#!/usr/bin/perl

# Generate strings from a grammar

# Denis Howe 1997-12-17 - 2018-09-19

# Numerical arg is number of utterances to utter
# Non-numerical arg is grammar file

# http://foldoc.org/pub/misc/say.pl

$fail = "FAIL";
$web = defined $ENV{REQUEST_METHOD};

# ############################################################################ #
# Generate sentences

print "Content-type: text/html\n\n<pre>\n" if ($web);

@ARGV = split /&/, $ENV{QUERY_STRING} if ($web);
my ($count) = grep !/\D/, @ARGV; $count ||= 1;
@ARGV = grep /\D/, @ARGV;
$last_mod = ${[stat $0]}[9];

# srand 9;

do
{
	exec $0 if (${[stat $0]}[9] ne $last_mod);
	read_grammar();
	my @exp;
	do {@exp = check(1, expand($topcat))} while ("@exp" eq $fail);
	display("@exp");
} while (--$count);

exit 0;

# ############################################################################ #

# Recursively expand a category and return a checked list

sub expand
{
	my $cat = shift;
	print "EXPANDING $cat\n"; # unless ($web);
	my $expsref = $expsref{$cat};
	return $cat unless ($expsref);
	my @exps = @$expsref;				# All possible expansions
	my $i = int(rand() * ($#exps + 1));
	my $expref = $exps[$i];				# Pick one expansion
	my @all = ();
	my $prefix;
	foreach (@$expref)					# Recurse on each subcategory
	{
		if (/^@=/) {$prefix = $'; next}	# Is this an object name?
		my @exp1 = expand($_);			# Expand this bit
		return $fail if ("@exp1" eq $fail);	# Pass up failure
		print "$_ -> @exp1\n"; # unless ($web);
		push @all, @exp1;				# Accumulate processed bits
	}
	@all = prefix($prefix, @all) if ($prefix);
	return check(0, @all);				# Don't check "need" constraints yet
}


# Return undef unless attributes in arg words are compatible.
# First arg says whether to check '?' constraints.

sub check
{
	my $check_need = shift;

	return $fail if "@_" eq $fail;

	my %attribute;

	print "CHECKING: @_\n\n"; # unless ($web);
	# Collect all bindings
	foreach (@_)
	{
		while (/(\S+)=(\S*)/g)			# Check/bind "=" constraints
		{
			if (defined $attribute{$1} && $attribute{$1} ne $2)
			{
				print "= failure: $attribute{$1} != $2\n\n"; # unless ($web);
				return $fail;
			}
			$attribute{$1} = $2;
		}
	}
	foreach (@_)						# Check "!" constraints
	{
		while (/(\S+)!(\S*)/g)
		{
			if ($attribute{$1} eq $2)
			{
				print "! failure: [$1] $attribute{$1} == $2\n\n"; # unless ($web);
				return $fail;
			}
		}
	}
	if ($check_need)
	{
		foreach (@_)						# Check "?" constraints
		{
			while (/(\S+)\?(\S*)/g)
			{
				if ($attribute{$1} ne $2)
				{
					print "? failure: $attribute{$1} != $2\n\n"; # unless ($web);
					return $fail;
				}
			}
		}
	}
	return @_;
}


sub strip_attributes
{
	1 while (s/(\S+)[=!?](\S+)//);
}


# Prefix "ARG." to all attributes and return the list

sub prefix
{
	my $prefix = shift() . '.';
	my @result;
	foreach (@_)
	{
		$_ = "$prefix$_" if (/\S+[=!?]\S+/);
		push @result, $_;
	}
	print "PREFIXED: $prefix  TO: @result\n"; # unless ($web);
	return @result;
}


# Return the plural of a noun or third person singular of a verb

sub plural
{
	local $_ = shift;

	s/([cs]h|x|ss)$/$1es/ ||
	s/us$/usses/		  ||
	s/([^ao])y$/$1ies/ 	  ||
	s/um$/a/ 			  ||
	s/$/s/;
	return $_;
}

# Read the grammar from the program DATA section

sub read_grammar
{
	local $_;
	if (@ARGV)
	{
		# Read the grammar from a file in the program directory
		$_ = $0; s|/?[^/]*$|| && chdir $_;
		$_ = $ARGV[0];
		die if (/[^-_A-Za-z0-9]/);		# Security check
		open DATA, $_;
	}
	while ($_ = <DATA>)					# One production
	{
		next if (/^#/ || /^$/);
		chomp;
		my ($l, $r) = split /:\s*/, $_;			# Split at ':'
		$topcat = $l unless (defined $topcat);	# The start category
		foreach (decline($l, $r)) {push @{$expsref{$l}}, [split /\s+/, $_]}
	}
	close DATA;
}


# Given the left and right sides of a production, return a list of possible variants of the root

sub decline
{
	my ($l, $r) = @_;

	if ($r !~ /=/)	# Only munge unconstrained productions
	{
		my ($root, $rest) = split(/ /, $r);
		# Comparatives and superlatives of adjectives
		if ($l eq 'adjective')
		{
			my @alts;
			# push @alts, $r;
			my $syls = syllables($root);
			my $com = $root;
			if ($syls < 3)
			{
				$com =~ s/([^aeo])y$/$1i/ if ($syls == 2);
				push @alts, $com . 'er', $com . 'est';
			}
			else
			{
				push @alts, "more $r ADJ_QUAL=MORE", "most $r ADJ_QUAL=MOST";
			}
			return @alts;
		}
		# Singular and plural of noun
		if ($l eq 'noun') {return ("$r NUMBER=SINGULAR",
								   plural($root) . " $rest NUMBER=PLURAL")}

		# Use "plural" of verb for 3rd person singular agents, e.g. "he
		# runS".  There should be just one other expansion for other agents
		# (using the unmodified form of the verb) but we can't express
		# (!THIRD OR =PLURAL) so we add them as two seprate expansions.

		if ($l eq 'verb') {return (plural($root) . " $rest AGENT.PERSON=THIRD AGENT.NUMBER=SINGULAR",
								   "$r AGENT.PERSON!THIRD",
								   "$r AGENT.NUMBER=PLURAL")}
	}
	return ($r);						# Otherwise just as it comes
}


# Return the number of syllables in WORD

sub syllables
{
	local $_ = shift;
	s/[aeiouy]+/a/; s/[^aeiouy]+//;
	return length($_);
}


sub display
{
	local $_ = shift;

	strip_attributes();
	# Clean up punctuation
	s/\s+/ /g;
	s/^\s+//;				# Lose initial space
	s/\ba( [aeiou])/an$1/g;	# a->an before vowel
	s/\s+([.?!,'])/$1/g;	# Zap space before punctuation
	s/./uc $&/e;			# Initial capital
	s|\s*//\s*|$web ? "<p>" : "\n\n"|eg; # Paragraph
	print "$_\n\n\n";
	print "<hr>\n" if ($web);
}

# ############################################################################ #

# Metagrammar

# grammar:  prod+
# prod:     catname ":" qcon+ newline
# catname:  string
# qcon:		constit [attrib rel value]*
# constit:  catname
# constit:  literal
# attrib:   string [ "." attrib ]
# value	:   string
# literal:  string		(Any string that is not a category name)
# rel:      "=" | "?" | "!"


# Attributes

# @			(foo) prefixes "foo." to all attributes at this level
# ADJ_QUAL	(ADVERB, INTENSIFIER, MORE, MOST) of an adjective
# AGENT		The np that is the subject of the verb
# NUMBER	(SINGULAR, PLURAL, UNCOUNTABLE) of a np
# PERSON	(FIRST, SECOND, THIRD) of an object np
# QUALIFY	(ADJECTIVE, VERB) of an adverb
# ROLE		(SUBJECT, OBJECT) of a np
# STYPE		(QUESTION) of a sentence
# SPECIFIC	(YES) of a np - has a det
# THIRDSING	(YES, NO) of a np
# WITH		(YES) of a pp - prep is "with"

# Semantic objects
# OBJECT	The np to which the verb is done
# PP		A prepositional phrase
# SUBJECT	The do-er np of the verb

__DATA__

sentence: statement
# sentence: AGENT.PERSON=SECOND verb_phrase final_punctuation
# sentence: interjection final_punctuation
statement: verb_qualifiers subject_phrase verb_phrase verb_qualifiers final_punctuation

subject_phrase: noun_phrase ROLE=SUBJECT @=AGENT

# [all [of]] [my | the] cats
# [all [of]] {my | the} cat
# [some] cats
# [[some of] my] cats
# every cat
# [every] one of the cats
# a cat
# [very] blue cats

# ############################################################################ #

noun_phrase: non_pro_noun_phrase PERSON=THIRD
noun_phrase: pronoun

non_pro_noun_phrase: noun_qualifiers adjective_noun
non_pro_noun_phrase: proper_name PERSON=THIRD NUMBER=SINGULAR

noun_qualifiers: NUMBER=PLURAL
noun_qualifiers: quantifier
noun_qualifiers: opt_quantifier_of det SPECIFIC=YES

opt_quantifier_of:
opt_quantifier_of: quantifier_of of

opt_quantifier:
opt_quantifier: quantifier

opt_own:
opt_own: own

owner_phrase: my
owner_phrase: your
owner_phrase: his
owner_phrase: her
owner_phrase: its
owner_phrase: our
owner_phrase: their
owner_phrase: non_pro_noun_phrase 's

opt_of:
opt_of: of

adjective_noun: opt_adjectives noun

opt_adjectives:
opt_adjectives: opt_adjective_qualifier adjective
# opt_adjectives: opt_adjective_qualifier adjective opt_adjectives

# Only one ADJ_QUAL per adjective, including more/most from lexical generation
opt_adjective_qualifier:
opt_adjective_qualifier: adverb QUALIFY=ADJECTIVE ADJ_QUAL=ADVERB
opt_adjective_qualifier: intensifier ADJ_QUAL=INTENSIFIER

proper_name: Denis
proper_name: Simin
proper_name: James
proper_name: Mark
proper_name: Saguna
proper_name: Santosh
proper_name: Simon
proper_name: Alex
proper_name: Tony

number_phrase: one NUMBER=SINGULAR
number_phrase: two NUMBER=PLURAL
number_phrase: a hundred NUMBER=PLURAL

verb_phrase: verb opt_object

opt_object:
opt_object: noun_phrase ROLE=OBJECT

verb_qualifiers:
verb_qualifiers:
verb_qualifiers: verb_qualifier
verb_qualifiers: verb_qualifier verb_qualifiers

verb_qualifier: adverb QUALIFY=VERB
# Hide nouns in the pp from subject and object conditions
verb_qualifier: prepositional_phrase @=PP

prepositional_phrase: preposition noun_phrase ROLE=OBJECT

final_punctuation: . AGENT.STYPE!QUESTION AGENT.ROLE?SUBJECT
final_punctuation: ? AGENT.STYPE?QUESTION
final_punctuation: ! AGENT.ROLE!SUBJECT

adjective: able
adjective: abnormal
adjective: above
adjective: absent
adjective: absolute
adjective: abstract
adjective: absurd
adjective: academic
adjective: acceptable
adjective: accessible
adjective: accounting
adjective: accurate
adjective: accused
adjective: active
adjective: actual
adjective: acute
adjective: added
adjective: additional
adjective: adequate
adjective: adjacent
adjective: administrative
adjective: adult
adjective: advanced
adjective: adverse
adjective: advisory
adjective: aesthetic
adjective: afraid
adjective: aggregate
adjective: aggressive
adjective: agreed
adjective: agricultural
adjective: alert
adjective: alien
adjective: alive
adjective: alleged
adjective: allied
adjective: alone
adjective: alright
adjective: alternative
adjective: amateur
adjective: amazing
adjective: ambiguous
adjective: ambitious
adjective: ample
adjective: ancient
adjective: angry
adjective: annual
adjective: anonymous
adjective: anxious
adjective: appalling
adjective: apparent
adjective: applicable
adjective: applied
adjective: appointed
adjective: appropriate
adjective: approved
adjective: arbitrary
adjective: archaeological
adjective: architectural
adjective: armed
adjective: artificial
adjective: artistic
adjective: ashamed
adjective: asleep
adjective: assistant
adjective: associated
adjective: astonishing
adjective: atomic
adjective: attempted
adjective: attractive
adjective: automatic
adjective: autonomous
adjective: available
adjective: average
adjective: awake
adjective: aware
adjective: awful
adjective: awkward
adjective: back
adjective: bad
adjective: balanced
adjective: bare
adjective: basic
adjective: beautiful
adjective: beneficial
adjective: big
adjective: binding
adjective: biological
adjective: bitter
adjective: bizarre
adjective: black
adjective: blank
adjective: bleak
adjective: blind
adjective: blonde
adjective: bloody
adjective: blue
adjective: bodily
adjective: bold
adjective: bored
adjective: boring
adjective: bottom
adjective: bourgeois
adjective: brave
adjective: brief
adjective: bright
adjective: brilliant
adjective: broad
adjective: broken
adjective: brown
adjective: bureaucratic
adjective: burning
adjective: busy
adjective: calm
adjective: capable
adjective: capital
adjective: careful
adjective: casual
adjective: causal
adjective: cautious
adjective: central
adjective: certain
adjective: changing
adjective: characteristic
adjective: charming
adjective: cheap
adjective: cheerful
adjective: chemical
adjective: chief
adjective: chosen
adjective: chronic
adjective: circular
adjective: civic
adjective: civil
adjective: civilian
adjective: classic
adjective: classical
adjective: clean
adjective: clear
adjective: clerical
adjective: clever
adjective: clinical
adjective: close
adjective: closed
adjective: co-operative
adjective: coastal
adjective: cognitive
adjective: coherent
adjective: cold
adjective: collective
adjective: colonial
adjective: coloured
adjective: colourful
adjective: combined
adjective: comfortable
adjective: coming
adjective: commercial
adjective: common
adjective: communist
adjective: comparable
adjective: comparative
adjective: compatible
adjective: competent
adjective: competitive
adjective: complementary
adjective: complete
adjective: complex
adjective: complicated
adjective: comprehensive
adjective: compulsory
adjective: conceptual
adjective: concerned
adjective: concrete
adjective: confident
adjective: confidential
adjective: conscious
adjective: conservative
adjective: considerable
adjective: consistent
adjective: constant
adjective: constitutional
adjective: constructive
adjective: contemporary
adjective: content
adjective: continental
adjective: continued
adjective: continuing
adjective: continuous
adjective: contractual
adjective: contrary
adjective: controlled
adjective: controversial
adjective: convenient
adjective: conventional
adjective: convincing
adjective: cool
adjective: corporate
adjective: correct
adjective: corresponding
adjective: costly
adjective: crazy
adjective: creative
adjective: criminal
adjective: critical
adjective: crucial
adjective: crude
adjective: cruel
adjective: cultural
adjective: curious
adjective: current
adjective: daily
adjective: damaging
adjective: damp
adjective: dangerous
adjective: dark
adjective: dead
adjective: deadly
adjective: deaf
adjective: dear
adjective: decent
adjective: decisive
adjective: decorative
adjective: deep
adjective: defensive
adjective: definite
adjective: deliberate
adjective: delicate
adjective: delicious
adjective: delighted
adjective: delightful
adjective: democratic
adjective: dense
adjective: departmental
adjective: dependent
adjective: depending
adjective: depressed
adjective: desirable
adjective: desired
adjective: desperate
adjective: detailed
adjective: determined
adjective: developed
adjective: developing
adjective: devoted
adjective: different
adjective: differential
adjective: difficult
adjective: digital
adjective: diplomatic
adjective: direct
adjective: dirty
adjective: disabled
adjective: disastrous
adjective: disciplinary
adjective: distant
adjective: distinct
adjective: distinctive
adjective: distinguished
adjective: distributed
adjective: diverse
adjective: divine
adjective: domestic
adjective: dominant
adjective: double
adjective: doubtful
adjective: dramatic
adjective: dreadful
adjective: driving
adjective: drunk
adjective: dry
adjective: dual
adjective: due
adjective: dull
adjective: dynamic
adjective: eager
adjective: early
adjective: eastern
adjective: easy
adjective: economic
adjective: educational
adjective: effective
adjective: efficient
adjective: elaborate
adjective: elderly
adjective: elected
adjective: electoral
adjective: electric
adjective: electrical
adjective: electronic
adjective: elegant
adjective: eligible
adjective: embarrassed
adjective: embarrassing
adjective: emotional
adjective: empirical
adjective: empty
adjective: encouraging
adjective: endless
adjective: enhanced
adjective: enjoyable
adjective: enormous
adjective: enthusiastic
adjective: entire
adjective: environmental
adjective: equal
adjective: equivalent
adjective: essential
adjective: established
adjective: estimated
adjective: eternal
adjective: ethical
adjective: ethnic
adjective: eventual
adjective: everyday
adjective: evident
adjective: evil
adjective: evolutionary
adjective: exact
adjective: excellent
adjective: exceptional
adjective: excess
adjective: excessive
adjective: excited
adjective: exciting
adjective: exclusive
adjective: executive
adjective: existing
adjective: exotic
adjective: expected
adjective: expensive
adjective: experienced
adjective: experimental
adjective: expert
adjective: explicit
adjective: express
adjective: extended
adjective: extensive
adjective: external
adjective: extra
adjective: extraordinary
adjective: extreme
adjective: faint
adjective: fair
adjective: faithful
adjective: FALSE
adjective: familiar
adjective: famous
adjective: fantastic
adjective: far
adjective: fascinating
adjective: fashionable
adjective: fast
adjective: fat
adjective: fatal
adjective: favourable
adjective: favourite
adjective: feasible
adjective: federal
adjective: fellow
adjective: female
adjective: feminine
adjective: fierce
adjective: final
adjective: financial
adjective: fine
adjective: finished
adjective: firm
adjective: first
adjective: fiscal
adjective: fit
adjective: fixed
adjective: flat
adjective: flexible
adjective: following
adjective: fond
adjective: foolish
adjective: foreign
adjective: formal
adjective: former
adjective: formidable
adjective: forthcoming
adjective: fortunate
adjective: forward
adjective: fragile
adjective: free
adjective: frequent
adjective: fresh
adjective: friendly
adjective: frightened
adjective: front
adjective: frozen
adjective: fucking
adjective: full
adjective: full-time
adjective: fun
adjective: functional
adjective: fundamental
adjective: funny
adjective: furious
adjective: future
adjective: gastric
adjective: gay
adjective: general
adjective: generous
adjective: genetic
adjective: gentle
adjective: genuine
adjective: geographical
adjective: geological
adjective: giant
adjective: given
adjective: glad
adjective: global
adjective: glorious
adjective: gold
adjective: golden
adjective: good
adjective: gothic
adjective: gradual
adjective: grammatical
adjective: grand
adjective: grateful
adjective: grave
adjective: great
adjective: green
adjective: grey
adjective: grim
adjective: gross
adjective: growing
adjective: guilty
adjective: handicapped
adjective: handsome
adjective: handy
adjective: happy
adjective: hard
adjective: harmful
adjective: harsh
adjective: head
adjective: healthy
adjective: heavy
adjective: helpful
adjective: helpless
adjective: hidden
adjective: high
adjective: historic
adjective: historical
adjective: holy
adjective: homeless
adjective: homosexual
adjective: honest
adjective: honourable
adjective: horizontal
adjective: horrible
adjective: hostile
adjective: hot
adjective: huge
adjective: human
adjective: humble
adjective: hungry
adjective: ideal
adjective: identical
adjective: ideological
adjective: ill
adjective: illegal
adjective: imaginative
adjective: immediate
adjective: immense
adjective: imminent
adjective: immune
adjective: imperial
adjective: implicit
adjective: important
adjective: impossible
adjective: impressive
adjective: improved
adjective: inadequate
adjective: inappropriate
adjective: incapable
adjective: inclined
adjective: increased
adjective: increasing
adjective: incredible
adjective: independent
adjective: indigenous
adjective: indirect
adjective: individual
adjective: indoor
adjective: industrial
adjective: inevitable
adjective: infinite
adjective: influential
adjective: informal
adjective: inherent
adjective: initial
adjective: injured
adjective: inland
adjective: inner
adjective: innocent
adjective: innovative
adjective: instant
adjective: institutional
adjective: instrumental
adjective: insufficient
adjective: intact
adjective: integral
adjective: integrated
adjective: intellectual
adjective: intelligent
adjective: intense
adjective: intensive
adjective: intent
adjective: interactive
adjective: interested
adjective: interesting
adjective: interim
adjective: interior
adjective: intermediate
adjective: internal
adjective: international
adjective: intimate
adjective: invaluable
adjective: invisible
adjective: involved
adjective: irrelevant
adjective: irrespective
adjective: isolated
adjective: jealous
adjective: joint
adjective: judicial
adjective: junior
adjective: just
adjective: justified
adjective: keen
adjective: key
adjective: kind
adjective: known
adjective: labour
adjective: lacking
adjective: large
adjective: large-scale
adjective: last
adjective: late
adjective: latin
adjective: latter
adjective: lay
adjective: lazy
adjective: leading
adjective: left
adjective: legal
adjective: legislative
adjective: legitimate
adjective: lengthy
adjective: lesser
adjective: level
adjective: lexical
adjective: liable
adjective: liberal
adjective: light
adjective: like
adjective: likely
adjective: limited
adjective: linear
adjective: linguistic
adjective: liquid
adjective: literary
adjective: little
adjective: live
adjective: lively
adjective: living
adjective: local
adjective: logical
adjective: lone
adjective: lonely
adjective: long
adjective: long-term
adjective: loose
adjective: lost
adjective: loud
adjective: lovely
adjective: low
adjective: loyal
adjective: lucky
adjective: luxury
adjective: mad
adjective: magic
adjective: magical
adjective: magnetic
adjective: magnificent
adjective: main
adjective: major
adjective: male
adjective: managerial
adjective: managing
adjective: mandatory
adjective: manual
adjective: manufacturing
adjective: marginal
adjective: marine
adjective: marked
adjective: married
adjective: marvellous
adjective: mass
adjective: massive
adjective: material
adjective: mathematical
adjective: mature
adjective: maximum
adjective: mean
adjective: meaningful
adjective: mechanical
adjective: medical
adjective: medieval
adjective: medium
adjective: memorable
adjective: mental
adjective: mere
adjective: metropolitan
adjective: mid
adjective: middle
adjective: middle-class
adjective: mighty
adjective: mild
adjective: military
adjective: minimal
adjective: minimum
adjective: ministerial
adjective: minor
adjective: minute
adjective: miserable
adjective: misleading
adjective: missing
adjective: mixed
adjective: mobile
adjective: moderate
adjective: modern
adjective: modest
adjective: molecular
adjective: monetary
adjective: monthly
adjective: moral
adjective: moving
adjective: multiple
adjective: municipal
adjective: musical
adjective: mutual
adjective: mysterious
adjective: naked
adjective: narrow
adjective: nasty
adjective: national
adjective: native
adjective: natural
adjective: naval
adjective: near
adjective: nearby
adjective: neat
adjective: necessary
adjective: negative
adjective: neighbouring
adjective: nervous
adjective: net
adjective: neutral
adjective: new
adjective: next
adjective: nice
adjective: noble
adjective: noisy
adjective: nominal
adjective: normal
adjective: northern
adjective: notable
adjective: noticeable
adjective: notorious
adjective: novel
adjective: nuclear
adjective: numerous
adjective: nursing
adjective: objective
adjective: obscure
adjective: obvious
adjective: occasional
adjective: occupational
adjective: odd
adjective: offensive
adjective: official
adjective: okay
adjective: old
adjective: old-fashioned
adjective: open
adjective: operational
adjective: opposed
adjective: opposite
adjective: optical
adjective: optimistic
adjective: optional
adjective: oral
adjective: orange
adjective: ordinary
adjective: organic
adjective: organisational
adjective: organizational
adjective: original
adjective: orthodox
adjective: other
adjective: outdoor
adjective: outer
adjective: outside
adjective: outstanding
adjective: overall
adjective: overseas
adjective: overwhelming
adjective: paid
adjective: painful
adjective: pale
adjective: papal
adjective: parallel
adjective: parental
adjective: parliamentary
adjective: part-time
adjective: partial
adjective: particular
adjective: passionate
adjective: passive
adjective: past
adjective: patient
adjective: payable
adjective: peaceful
adjective: peculiar
adjective: perceived
adjective: perfect
adjective: permanent
adjective: persistent
adjective: personal
adjective: petty
adjective: philosophical
adjective: photographic
adjective: physical
adjective: pink
adjective: plain
adjective: planned
adjective: plausible
adjective: pleasant
adjective: pleased
adjective: polish
adjective: polite
adjective: political
adjective: poor
adjective: popular
adjective: portable
adjective: positive
adjective: possible
adjective: post-war
adjective: potential
adjective: powerful
adjective: practical
adjective: precious
adjective: precise
adjective: predictable
adjective: preferred
adjective: pregnant
adjective: preliminary
adjective: premature
adjective: premier
adjective: present
adjective: presidential
adjective: pretty
adjective: previous
adjective: primary
adjective: prime
adjective: primitive
adjective: principal
adjective: printed
adjective: prior
adjective: private
adjective: privileged
adjective: probable
adjective: productive
adjective: professional
adjective: profitable
adjective: profound
adjective: progressive
adjective: prolonged
adjective: prominent
adjective: prone
adjective: proper
adjective: proportional
adjective: proposed
adjective: prospective
adjective: protective
adjective: proud
adjective: provincial
adjective: provisional
adjective: psychiatric
adjective: psychological
adjective: public
adjective: pure
adjective: purple
adjective: qualified
adjective: quantitative
adjective: quick
adjective: quiet
adjective: racial
adjective: radical
adjective: raised
adjective: random
adjective: rapid
adjective: rare
adjective: rational
adjective: raw
adjective: ready
adjective: real
adjective: realistic
adjective: rear
adjective: reasonable
adjective: recent
adjective: red
adjective: reduced
adjective: redundant
adjective: regional
adjective: regular
adjective: regulatory
adjective: related
adjective: relative
adjective: relevant
adjective: reliable
adjective: religious
adjective: reluctant
adjective: remaining
adjective: remarkable
adjective: remote
adjective: renewed
adjective: repeated
adjective: representative
adjective: required
adjective: resident
adjective: residential
adjective: respectable
adjective: respective
adjective: responsible
adjective: restricted
adjective: restrictive
adjective: resulting
adjective: retail
adjective: retired
adjective: revised
adjective: revolutionary
adjective: rich
adjective: ridiculous
adjective: right
adjective: rigid
adjective: rising
adjective: rival
adjective: romantic
adjective: rotten
adjective: rough
adjective: round
adjective: royal
adjective: rubber
adjective: rude
adjective: ruling
adjective: running
adjective: rural
adjective: sacred
adjective: sad
adjective: safe
adjective: satisfactory
adjective: satisfied
adjective: scared
adjective: scientific
adjective: seasonal
adjective: secondary
adjective: secret
adjective: secular
adjective: secure
adjective: select
adjective: selected
adjective: selective
adjective: semantic
adjective: senior
adjective: sensible
adjective: sensitive
adjective: separate
adjective: serious
adjective: severe
adjective: sexual
adjective: shallow
adjective: shared
adjective: sharp
adjective: sheer
adjective: shocked
adjective: short
adjective: short-term
adjective: shy
adjective: sick
adjective: significant
adjective: silent
adjective: silly
adjective: silver
adjective: similar
adjective: simple
adjective: single
adjective: skilled
adjective: sleeping
adjective: slight
adjective: slim
adjective: slow
adjective: small
adjective: smart
adjective: smooth
adjective: so-called
adjective: social
adjective: socialist
adjective: sociological
adjective: soft
adjective: solar
adjective: sole
adjective: solid
adjective: sophisticated
adjective: sore
adjective: sorry
adjective: sound
adjective: southern
adjective: spare
adjective: spatial
adjective: special
adjective: specialist
adjective: specific
adjective: specified
adjective: spectacular
adjective: spiritual
adjective: splendid
adjective: spoken
adjective: spontaneous
adjective: square
adjective: stable
adjective: standard
adjective: static
adjective: statistical
adjective: statutory
adjective: steady
adjective: steep
adjective: sterling
adjective: sticky
adjective: stiff
adjective: still
adjective: stolen
adjective: straight
adjective: straightforward
adjective: strange
adjective: strategic
adjective: strict
adjective: striking
adjective: strong
adjective: structural
adjective: stunning
adjective: stupid
adjective: subject
adjective: subjective
adjective: subsequent
adjective: substantial
adjective: substantive
adjective: subtle
adjective: successful
adjective: successive
adjective: sudden
adjective: sufficient
adjective: suitable
adjective: sunny
adjective: super
adjective: superb
adjective: superior
adjective: supplementary
adjective: supporting
adjective: supposed
adjective: supreme
adjective: sure
adjective: surplus
adjective: surprised
adjective: surprising
adjective: surrounding
adjective: suspicious
adjective: sweet
adjective: swift
adjective: symbolic
adjective: sympathetic
adjective: syntactic
adjective: systematic
adjective: talented
adjective: tall
adjective: technical
adjective: technological
adjective: teenage
adjective: temporary
adjective: tender
adjective: tense
adjective: terminal
adjective: terrible
adjective: territorial
adjective: theoretical
adjective: thick
adjective: thin
adjective: thinking
adjective: thorough
adjective: tight
adjective: tiny
adjective: tired
adjective: top
adjective: total
adjective: tough
adjective: toxic
adjective: trading
adjective: traditional
adjective: tragic
adjective: trained
adjective: tremendous
adjective: trivial
adjective: tropical
adjective: true
adjective: typical
adjective: ugly
adjective: ultimate
adjective: unable
adjective: unacceptable
adjective: unaware
adjective: uncertain
adjective: unchanged
adjective: unclear
adjective: uncomfortable
adjective: unconscious
adjective: underground
adjective: underlying
adjective: understandable
adjective: uneasy
adjective: unemployed
adjective: unexpected
adjective: unfair
adjective: unfamiliar
adjective: unfortunate
adjective: unhappy
adjective: uniform
adjective: unique
adjective: united
adjective: universal
adjective: unknown
adjective: unlawful
adjective: unlike
adjective: unlikely
adjective: unnecessary
adjective: unpleasant
adjective: unprecedented
adjective: unreasonable
adjective: unsuccessful
adjective: unusual
adjective: unwanted
adjective: unwilling
adjective: up-to-date
adjective: upper
adjective: upset
adjective: urban
adjective: urgent
adjective: used
adjective: useful
adjective: useless
adjective: usual
adjective: vacant
adjective: vague
adjective: valid
adjective: valuable
adjective: variable
adjective: varied
adjective: various
adjective: varying
adjective: vast
adjective: verbal
adjective: vertical
adjective: viable
adjective: vicious
adjective: video-taped
adjective: vigorous
adjective: violent
adjective: virtual
adjective: visible
adjective: visual
adjective: vital
adjective: vivid
adjective: vocational
adjective: voluntary
adjective: vulnerable
adjective: waiting
adjective: walking
adjective: warm
adjective: wary
adjective: waste
adjective: weak
adjective: wealthy
adjective: wee
adjective: weekly
adjective: weird
adjective: welcome
adjective: well
adjective: well-known
adjective: western
adjective: wet
adjective: white
adjective: whole
adjective: wicked
adjective: wide
adjective: widespread
adjective: wild
adjective: willing
adjective: winning
adjective: wise
adjective: wonderful
adjective: wooden
adjective: working
adjective: working-class
adjective: worldwide
adjective: worried
adjective: worrying
adjective: worthwhile
adjective: worthy
adjective: written
adjective: wrong
adjective: yellow
adjective: young

adverb: about
adverb: above
adverb: abroad
adverb: abruptly
adverb: absolutely
adverb: accordingly
adverb: accurately
adverb: across
adverb: actively
adverb: actually
adverb: adequately
adverb: afterwards
adverb: again
adverb: ago
adverb: ahead
adverb: alike
adverb: all
adverb: allegedly
adverb: almost
adverb: alone
adverb: along
adverb: aloud
adverb: already
adverb: alright
adverb: also
adverb: alternatively
adverb: altogether
adverb: always
adverb: angrily
adverb: annually
adverb: anyway
adverb: anywhere
adverb: apart
adverb: apparently
adverb: appropriately
adverb: approximately
adverb: around
adverb: aside
adverb: automatically
adverb: away
adverb: back
adverb: backwards
adverb: badly
adverb: barely
adverb: basically
adverb: beautifully
adverb: before
adverb: behind
adverb: below
adverb: besides
adverb: best
adverb: better
adverb: beyond
adverb: bitterly
adverb: bloody
adverb: both
adverb: briefly
adverb: broadly
adverb: by
adverb: carefully
adverb: certainly
adverb: clearly
adverb: close
adverb: closely
adverb: comfortably
adverb: commonly
adverb: comparatively
adverb: completely
adverb: consequently
adverb: considerably
adverb: consistently
adverb: constantly
adverb: continually
adverb: continuously
adverb: conversely
adverb: correctly
adverb: curiously
adverb: currently
adverb: daily
adverb: dead
adverb: deep
adverb: deeply
adverb: definitely
adverb: deliberately
adverb: desperately
adverb: differently
adverb: direct
adverb: directly
adverb: distinctly
adverb: doubtless
adverb: down
adverb: downstairs
adverb: dramatically
adverb: duly
adverb: early
adverb: easily
adverb: easy
adverb: economically
adverb: effectively
adverb: efficiently
adverb: either
adverb: else
adverb: elsewhere
adverb: enormously
adverb: enough
adverb: entirely
adverb: equally
adverb: especially
adverb: essentially
adverb: even
adverb: eventually
adverb: everywhere
adverb: evidently
adverb: exactly
adverb: exceptionally
adverb: exclusively
adverb: explicitly
adverb: extensively
adverb: extremely
adverb: fair
adverb: fairly
adverb: far
adverb: fast
adverb: fiercely
adverb: finally
adverb: financially
adverb: firmly
adverb: firstly
adverb: for
adverb: forever
adverb: formally
adverb: formerly
adverb: forth
adverb: fortunately
adverb: forward
adverb: forwards
adverb: frankly
adverb: freely
adverb: frequently
adverb: fully
adverb: fundamentally
adverb: further
adverb: generally
adverb: gently
adverb: genuinely
adverb: gradually
adverb: greatly
adverb: half
adverb: halfway
adverb: happily
adverb: hard
adverb: hardly
adverb: hastily
adverb: heavily
adverb: hence
adverb: here
adverb: high
adverb: highly
adverb: historically
adverb: hitherto
adverb: home
adverb: honestly
adverb: hopefully
adverb: how
adverb: however
adverb: ideally
adverb: immediately
adverb: importantly
adverb: incidentally
adverb: increasingly
adverb: incredibly
adverb: indeed
adverb: independently
adverb: indirectly
adverb: individually
adverb: inevitably
adverb: initially
adverb: inside
adverb: instantly
adverb: instead
adverb: invariably
adverb: ironically
adverb: jointly
adverb: just
adverb: kindly
adverb: largely
adverb: late
adverb: lately
adverb: later
adverb: least
adverb: legally
adverb: less
adverb: lightly
adverb: like
adverb: likewise
adverb: literally
adverb: locally
adverb: long
adverb: loud
adverb: loudly
adverb: low
adverb: mainly
adverb: maybe
adverb: meanwhile
adverb: mentally
adverb: merely
adverb: more
adverb: moreover
adverb: most
adverb: mostly
adverb: much
adverb: namely
adverb: nationally
adverb: naturally
adverb: near
adverb: nearby
adverb: nearly
adverb: neatly
adverb: necessarily
adverb: neither
adverb: never
adverb: nevertheless
adverb: newly
adverb: next
adverb: nicely
adverb: no
adverb: nonetheless
adverb: normally
adverb: notably
adverb: now
adverb: nowadays
adverb: nowhere
adverb: obviously
adverb: occasionally
adverb: off
adverb: officially
adverb: often
adverb: okay
adverb: on
adverb: once
adverb: only
adverb: onwards
adverb: open
adverb: openly
adverb: opposite
adverb: originally
adverb: otherwise
adverb: out
adverb: outside
adverb: over
adverb: overall
adverb: overnight
adverb: overseas
adverb: partially
adverb: particularly
adverb: partly
adverb: perfectly
adverb: perhaps
adverb: permanently
adverb: personally
adverb: physically
adverb: please
adverb: politically
adverb: poorly
adverb: positively
adverb: possibly
adverb: potentially
adverb: practically
adverb: precisely
adverb: predominantly
adverb: presently
adverb: presumably
adverb: pretty QUALIFY!VERB
adverb: previously
adverb: primarily
adverb: principally
adverb: privately
adverb: probably
adverb: promptly
adverb: properly
adverb: publicly
adverb: purely
adverb: quick
adverb: quickly
adverb: quietly
adverb: quite
adverb: rapidly
adverb: rarely
adverb: rather
adverb: readily
adverb: really
adverb: reasonably
adverb: recently
adverb: regardless
adverb: regularly
adverb: relatively
adverb: reluctantly
adverb: remarkably
adverb: repeatedly
adverb: reportedly
adverb: respectively
adverb: right
adverb: rightly
adverb: roughly
adverb: round
adverb: sadly
adverb: safely
adverb: scarcely
adverb: secondly
adverb: seemingly
adverb: seldom
adverb: separately
adverb: seriously
adverb: severely
adverb: sexually
adverb: sharply
adverb: short
adverb: shortly
adverb: sideways
adverb: significantly
adverb: silently
adverb: similarly
adverb: simply
adverb: simultaneously
adverb: since
adverb: sincerely
adverb: slightly
adverb: slowly
adverb: smoothly
adverb: so
adverb: socially
adverb: softly
adverb: solely
adverb: somehow
adverb: sometimes
adverb: somewhat
adverb: somewhere
adverb: soon
adverb: specially
adverb: specifically
adverb: steadily
adverb: still
adverb: straight
adverb: strangely
adverb: strictly
adverb: strongly
adverb: subsequently
adverb: substantially
adverb: successfully
adverb: suddenly
adverb: sufficiently
adverb: supposedly
adverb: sure
adverb: surely
adverb: surprisingly
adverb: swiftly
adverb: technically
adverb: temporarily
adverb: terribly
adverb: then
adverb: there
adverb: thereafter
adverb: thereby
adverb: therefore
adverb: thick
adverb: this
adverb: thoroughly
adverb: though
adverb: through
adverb: thus
adverb: tight
adverb: tightly
adverb: today
adverb: together
adverb: tomorrow
adverb: tonight
adverb: too
adverb: totally
adverb: traditionally
adverb: truly
adverb: twice
adverb: typically
adverb: ultimately
adverb: under
adverb: underneath
adverb: undoubtedly
adverb: unexpectedly
adverb: unfortunately
adverb: unusually
adverb: up
adverb: upstairs
adverb: upwards
adverb: urgently
adverb: usually
adverb: utterly
adverb: vaguely
adverb: virtually
adverb: well
adverb: when
adverb: whenever
adverb: where
adverb: wherever
adverb: wholly
adverb: why
adverb: wide
adverb: widely
adverb: wildly
adverb: within
adverb: worldwide
adverb: worse
adverb: wrong
adverb: yesterday
adverb: yet

conjuction: after
conjuction: albeit
conjuction: although
conjuction: and
conjuction: as
conjuction: because
conjuction: before
conjuction: but
conjuction: considering
conjuction: cos
conjuction: except
conjuction: for
conjuction: furthermore
conjuction: if
conjuction: immediately
conjuction: like
conjuction: nor
conjuction: once
conjuction: or
conjuction: plus
conjuction: provided
conjuction: providing
conjuction: since
conjuction: so
conjuction: than
conjuction: that
conjuction: though
conjuction: till
conjuction: unless
conjuction: until
conjuction: when
conjuction: where
conjuction: whereas
conjuction: whereby
conjuction: whether
conjuction: while
conjuction: whilst

intensifier: fucking
intensifier: very

# NUMBER of quantifier is number of following phrase
quantifier: number_phrase
quantifier: all NUMBER!SINGULAR
quantifier: every NUMBER=SINGULAR SPECIFIC!YES
quantifier: fewer NUMBER=PLURAL
quantifier: half SPECIFIC?YES
quantifier: less NUMBER=UNCOUNTABLE
quantifier: little NUMBER=UNCOUNTABLE SPECIFIC!YES
quantifier: no SPECIFIC!YES
quantifier: only SPECIFIC?YES
quantifier: some

quantifier_of: half
quantifier_of: none
quantifier_of: plenty
quantifier_of: quantifier

det: owner_phrase opt_own
det: a NUMBER=SINGULAR
det: another NUMBER=SINGULAR
det: any
det: both NUMBER=PLURAL
det: each NUMBER=SINGULAR
det: either NUMBER=SINGULAR
det: enough NUMBER=PLURAL
det: few NUMBER=PLURAL
det: fewer NUMBER=PLURAL
det: many NUMBER=PLURAL
det: more NUMBER=PLURAL
det: most NUMBER=PLURAL
det: much NUMBER=UNCOUNTABLE
det: neither NUMBER=SINGULAR
det: no
det: several NUMBER=PLURAL
det: some
det: such a NUMBER=SINGULAR
det: such NUMBER!SINGULAR
det: what STYPE=QUESTION
det: whatever
det: which STYPE=QUESTION
det: whichever
det: whose STYPE=QUESTION
det: det_opt_same opt_same

det_opt_same: the
det_opt_same: that NUMBER=SINGULAR
det_opt_same: these NUMBER=PLURAL
det_opt_same: this NUMBER=SINGULAR
det_opt_same: those NUMBER=PLURAL

opt_same:
opt_same: same

interjection: aye
interjection: bye
interjection: oh dear
interjection: ha
interjection: hello
interjection: hey
interjection: no
interjection: oh
interjection: ok
interjection: right
interjection: well
interjection: yeah
interjection: yep
interjection: yes

modal: can
modal: could
modal: may
modal: might
modal: must
modal: need
modal: ought
modal: shall
modal: should
modal: used
modal: will
modal: would

noun: abbey
noun: ability
noun: abolition
noun: abortion
noun: absence
noun: absorption
noun: abuse
noun: academic
noun: academy
noun: accent
noun: acceptance
noun: access
noun: accident
noun: accommodation
noun: accord
noun: accordance
noun: account
noun: accountability
noun: accountant
noun: accumulation
noun: accuracy
noun: accusation
noun: achievement
noun: acid
noun: acquaintance
noun: acquisition
noun: acre
noun: act
noun: action
noun: activist
noun: activity
noun: actor
noun: actress
noun: adaptation
noun: addition
noun: address
noun: adjective
noun: adjustment
noun: administration
noun: administrator
noun: admiration
noun: admission
noun: adoption
noun: adult
noun: advance
noun: advantage
noun: adventure
noun: advertisement
noun: advertising
noun: advice
noun: adviser
noun: advocate
noun: affair
noun: affection
noun: affinity
noun: afternoon
noun: age
noun: agency
noun: agenda
noun: agent
noun: aggression
noun: agony
noun: agreement
noun: agriculture
noun: aid
noun: aids
noun: aim
noun: air
noun: aircraft
noun: airline
noun: airport
noun: alarm
noun: album
noun: alcohol
noun: allegation
noun: alliance
noun: allocation
noun: allowance
noun: ally
noun: altar
noun: alteration
noun: alternative
noun: aluminium
noun: amateur
noun: ambassador
noun: ambiguity
noun: ambition
noun: ambulance
noun: amendment
noun: amount
noun: amp
noun: amusement
noun: analogy
noun: analysis
noun: analyst
noun: ancestor
noun: angel
noun: anger
noun: angle
noun: animal
noun: ankle
noun: anniversary
noun: announcement
noun: answer
noun: ant
noun: antibody
noun: anticipation
noun: anxiety
noun: apartment
noun: apology
noun: apparatus
noun: appeal
noun: appearance
noun: appendix
noun: appetite
noun: apple
noun: applicant
noun: application
noun: appointment
noun: appraisal
noun: appreciation
noun: approach
noun: approval
noun: aquarium
noun: arc
noun: arch
noun: archbishop
noun: architect
noun: architecture
noun: archive
noun: area
noun: arena
noun: argument
noun: arm
noun: armchair
noun: army
noun: arrangement
noun: array
noun: arrest
noun: arrival
noun: arrow
noun: art
noun: article
noun: artist
noun: ash
noun: aspect
noun: aspiration
noun: assault
noun: assembly
noun: assertion
noun: assessment
noun: asset
noun: assignment
noun: assistance
noun: assistant
noun: associate
noun: association
noun: assumption
noun: assurance
noun: asylum
noun: athlete
noun: atmosphere
noun: atom
noun: attachment
noun: attack
noun: attacker
noun: attainment
noun: attempt
noun: attendance
noun: attention
noun: attitude
noun: attraction
noun: attribute
noun: auction
noun: audience
noun: audit
noun: auditor
noun: aunt
noun: author
noun: authority
noun: autonomy
noun: autumn
noun: availability
noun: avenue
noun: average
noun: aviation
noun: award
noun: awareness
noun: axis
noun: baby
noun: back
noun: background
noun: backing
noun: bacon
noun: bacteria
noun: bag
noun: bail
noun: balance
noun: balcony
noun: ball
noun: ballet
noun: balloon
noun: ballot
noun: ban
noun: banana
noun: band
noun: bang
noun: bank
noun: banker
noun: banking
noun: bankruptcy
noun: banner
noun: bar
noun: bargain
noun: barn
noun: barrel
noun: barrier
noun: base
noun: basement
noun: basin
noun: basis
noun: basket
noun: bass
noun: bastard
noun: bat
noun: batch
noun: bath
noun: bathroom
noun: battery
noun: battle
noun: bay
noun: beach
noun: beam
noun: bean
noun: bear
noun: beard
noun: bearing
noun: beast
noun: beat
noun: beauty
noun: bed
noun: bedroom
noun: bee
noun: beef
noun: beer
noun: beginning
noun: behalf
noun: behaviour
noun: being
noun: belief
noun: bell
noun: belly
noun: belt
noun: bench
noun: bend
noun: beneficiary
noun: benefit
noun: bet
noun: bias
noun: bible
noun: bicycle
noun: bid
noun: bike
noun: bile
noun: bill
noun: bin
noun: biography
noun: biology
noun: bird
noun: birth
noun: birthday
noun: biscuit
noun: bishop
noun: bit
noun: bitch
noun: bite
noun: black
noun: blade
noun: blame
noun: blanket
noun: blast
noun: blessing
noun: block
noun: bloke
noun: blood
noun: blow
noun: blue
noun: board
noun: boat
noun: body
noun: boiler
noun: bolt
noun: bomb
noun: bomber
noun: bond
noun: bone
noun: bonus
noun: book
noun: booking
noun: booklet
noun: boom
noun: boost
noun: boot
noun: border
noun: borough
noun: boss
noun: bottle
noun: bottom
noun: boundary
noun: bow
noun: bowel
noun: bowl
noun: bowler
noun: box
noun: boxing
noun: boy
noun: boyfriend
noun: bracket
noun: brain
noun: brake
noun: branch
noun: brand
noun: brandy
noun: brass
noun: breach
noun: bread
noun: break
noun: breakdown
noun: breakfast
noun: breast
noun: breath
noun: breed
noun: breeding
noun: breeze
noun: brewery
noun: brick
noun: bride
noun: bridge
noun: brigade
noun: broadcast
noun: brochure
noun: broker
noun: bronze
noun: brother
noun: brow
noun: brush
noun: bubble
noun: bucket
noun: budget
noun: builder
noun: building
noun: bulb
noun: bulk
noun: bull
noun: bullet
noun: bulletin
noun: bunch
noun: bundle
noun: burden
noun: bureau
noun: bureaucracy
noun: burial
noun: burn
noun: burst
noun: bus
noun: bush
noun: business
noun: businessman
noun: butter
noun: butterfly
noun: button
noun: buyer
noun: cab
noun: cabin
noun: cabinet
noun: cable
noun: cafe
noun: cage
noun: cake
noun: calcium
noun: calculation
noun: calendar
noun: calf
noun: call
noun: calm
noun: calorie
noun: camera
noun: camp
noun: campaign
noun: can
noun: canal
noun: cancer
noun: candidate
noun: candle
noun: canvas
noun: cap
noun: capability
noun: capacity
noun: capital
noun: capitalism
noun: capitalist
noun: captain
noun: car
noun: caravan
noun: carbon
noun: card
noun: care
noun: career
noun: carer
noun: cargo
noun: carpet
noun: carriage
noun: carrier
noun: carrot
noun: cart
noun: case
noun: cash
noun: cassette
noun: cast
noun: castle
noun: casualty
noun: cat
noun: catalogue
noun: catch
noun: category
noun: cathedral
noun: cattle
noun: cause
noun: caution
noun: cave
noun: ceiling
noun: celebration
noun: cell
noun: cellar
noun: cemetery
noun: census
noun: centre
noun: century
noun: cereal
noun: ceremony
noun: certainty
noun: certificate
noun: chain
noun: chair
noun: chairman
noun: chalk
noun: challenge
noun: chamber
noun: champagne
noun: champion
noun: championship
noun: chance
noun: chancellor
noun: change
noun: channel
noun: chaos
noun: chap
noun: chapel
noun: chapter
noun: character
noun: characteristic
noun: charge
noun: charity
noun: charm
noun: chart
noun: charter
noun: chase
noun: chat
noun: check
noun: cheek
noun: cheese
noun: chemical
noun: chemist
noun: chemistry
noun: cheque
noun: chest
noun: chicken
noun: chief
noun: child
noun: childhood
noun: chimney
noun: chin
noun: chip
noun: chocolate
noun: choice
noun: choir
noun: chord
noun: chorus
noun: church
noun: cigarette
noun: cinema
noun: circle
noun: circuit
noun: circular
noun: circulation
noun: circumstance
noun: citizen
noun: citizenship
noun: city
noun: civilian
noun: civilization
noun: claim
noun: clarity
noun: clash
noun: class
noun: classic
noun: classification
noun: classroom
noun: clause
noun: clay
noun: cleaner
noun: clearance
noun: clearing
noun: clergy
noun: clerk
noun: client
noun: cliff
noun: climate
noun: climb
noun: climber
noun: clinic
noun: clock
noun: closure
noun: cloth
noun: clothes
noun: clothing
noun: cloud
noun: club
noun: clue
noun: cluster
noun: co-operation
noun: coach
noun: coal
noun: coalition
noun: coast
noun: coat
noun: code
noun: coffee
noun: coffin
noun: coin
noun: coincidence
noun: cold
noun: collaboration
noun: collapse
noun: collar
noun: colleague
noun: collection
noun: collector
noun: college
noun: colon
noun: colonel
noun: colony
noun: colour
noun: column
noun: combination
noun: comedy
noun: comfort
noun: command
noun: commander
noun: comment
noun: commentary
noun: commentator
noun: commerce
noun: commission
noun: commissioner
noun: commitment
noun: committee
noun: commodity
noun: commons
noun: commonwealth
noun: communication
noun: communism
noun: communist
noun: community
noun: compact
noun: companion
noun: company
noun: comparison
noun: compartment
noun: compensation
noun: competence
noun: competition
noun: competitor
noun: complaint
noun: completion
noun: complex
noun: complexity
noun: compliance
noun: complication
noun: component
noun: composer
noun: composition
noun: compound
noun: compromise
noun: computer
noun: computing
noun: concentration
noun: concept
noun: conception
noun: concern
noun: concert
noun: concession
noun: conclusion
noun: concrete
noun: condition
noun: conduct
noun: conductor
noun: conference
noun: confession
noun: confidence
noun: configuration
noun: confirmation
noun: conflict
noun: confrontation
noun: confusion
noun: congregation
noun: congress
noun: conjunction
noun: connection
noun: conscience
noun: consciousness
noun: consensus
noun: consent
noun: consequence
noun: conservation
noun: conservative
noun: consideration
noun: consistency
noun: consortium
noun: conspiracy
noun: constable
noun: constituency
noun: constituent
noun: constitution
noun: constraint
noun: construction
noun: consultant
noun: consultation
noun: consumer
noun: consumption
noun: contact
noun: container
noun: contemporary
noun: contempt
noun: content
noun: contest
noun: context
noun: continent
noun: continuation
noun: continuity
noun: contract
noun: contraction
noun: contractor
noun: contradiction
noun: contrary
noun: contrast
noun: contribution
noun: control
noun: controller
noun: controversy
noun: convenience
noun: convention
noun: conversation
noun: conversion
noun: conviction
noun: cook
noun: cooking
noun: cooperation
noun: copper
noun: copy
noun: copyright
noun: cord
noun: core
noun: corn
noun: corner
noun: corps
noun: corpse
noun: correction
noun: correlation
noun: correspondence
noun: correspondent
noun: corridor
noun: corruption
noun: cost
noun: costume
noun: cottage
noun: cotton
noun: council
noun: councillor
noun: counsel
noun: counselling
noun: counsellor
noun: count
noun: counter
noun: counterpart
noun: country
noun: countryside
noun: county
noun: coup
noun: couple
noun: courage
noun: course
noun: court
noun: courtesy
noun: courtyard
noun: cousin
noun: covenant
noun: cover
noun: coverage
noun: cow
noun: crack
noun: craft
noun: craftsman
noun: crash
noun: cream
noun: creation
noun: creature
noun: credibility
noun: credit
noun: creditor
noun: creed
noun: crew
noun: cricket
noun: crime
noun: criminal
noun: crisis
noun: criterion
noun: critic
noun: criticism
noun: critique
noun: crop
noun: cross
noun: crossing
noun: crowd
noun: crown
noun: cruelty
noun: cry
noun: crystal
noun: cult
noun: culture
noun: cup
noun: cupboard
noun: cure
noun: curiosity
noun: curl
noun: currency
noun: current
noun: curriculum
noun: curtain
noun: curve
noun: cushion
noun: custody
noun: custom
noun: customer
noun: cut
noun: cutting
noun: cycle
noun: cylinder
noun: dairy
noun: damage
noun: dance
noun: dancer
noun: dancing
noun: danger
noun: dark
noun: darkness
noun: darling
noun: data
noun: database
noun: date
noun: daughter
noun: dawn
noun: day
noun: daylight
noun: deadline
noun: deal
noun: dealer
noun: dealing
noun: dear
noun: death
noun: debate
noun: debt
noun: debtor
noun: debut
noun: decade
noun: decay
noun: decision
noun: decision-making
noun: deck
noun: declaration
noun: decline
noun: decoration
noun: decrease
noun: decree
noun: deed
noun: deer
noun: default
noun: defeat
noun: defect
noun: defence
noun: defendant
noun: defender
noun: deficiency
noun: deficit
noun: definition
noun: degree
noun: delay
noun: delegate
noun: delegation
noun: delight
noun: delivery
noun: demand
noun: democracy
noun: democrat
noun: demonstration
noun: demonstrator
noun: denial
noun: density
noun: dentist
noun: department
noun: departure
noun: dependence
noun: dependency
noun: deposit
noun: depot
noun: depression
noun: deprivation
noun: depth
noun: deputy
noun: descent
noun: description
noun: desert
noun: design
noun: designer
noun: desire
noun: desk
noun: desktop
noun: despair
noun: destination
noun: destiny
noun: destruction
noun: detail
noun: detection
noun: detective
noun: detector
noun: detention
noun: determination
noun: developer
noun: development
noun: deviation
noun: device
noun: devil
noun: diagnosis
noun: diagram
noun: dialogue
noun: diameter
noun: diamond
noun: diary
noun: dictionary
noun: diet
noun: difference
noun: differentiation
noun: difficulty
noun: dignity
noun: dilemma
noun: dimension
noun: dining
noun: dinner
noun: dioxide
noun: diplomat
noun: direction
noun: directive
noun: director
noun: directory
noun: dirt
noun: disability
noun: disadvantage
noun: disagreement
noun: disappointment
noun: disaster
noun: disc
noun: discharge
noun: discipline
noun: disclosure
noun: disco
noun: discount
noun: discourse
noun: discovery
noun: discretion
noun: discrimination
noun: discussion
noun: disease
noun: dish
noun: disk
noun: dismissal
noun: disorder
noun: display
noun: disposal
noun: disposition
noun: dispute
noun: disruption
noun: distance
noun: distinction
noun: distortion
noun: distress
noun: distribution
noun: distributor
noun: district
noun: disturbance
noun: diversity
noun: dividend
noun: division
noun: divorce
noun: dock
noun: doctor
noun: doctrine
noun: document
noun: documentation
noun: dog
noun: doing
noun: doll
noun: dollar
noun: dolphin
noun: domain
noun: dome
noun: dominance
noun: domination
noun: donation
noun: donor
noun: door
noun: doorway
noun: dose
noun: dot
noun: double
noun: doubt
noun: dozen
noun: draft
noun: dragon
noun: drain
noun: drainage
noun: drama
noun: draw
noun: drawer
noun: drawing
noun: dream
noun: dress
noun: dressing
noun: drift
noun: drill
noun: drink
noun: drive
noun: driver
noun: drop
noun: drug
noun: drum
noun: duck
noun: duke
noun: duration
noun: dust
noun: duty
noun: dwelling
noun: eagle
noun: ear
noun: earl
noun: earning
noun: earth
noun: ease
noun: east
noun: echo
noun: economics
noun: economist
noun: economy
noun: edge
noun: edition
noun: editor
noun: education
noun: effect
noun: effectiveness
noun: efficiency
noun: effort
noun: egg
noun: ego
noun: elbow
noun: elder
noun: election
noun: electorate
noun: electricity
noun: electron
noun: electronics
noun: element
noun: elephant
noun: elite
noun: embarrassment
noun: embassy
noun: embryo
noun: emergence
noun: emergency
noun: emission
noun: emotion
noun: emperor
noun: emphasis
noun: empire
noun: employee
noun: employer
noun: employment
noun: encounter
noun: encouragement
noun: end
noun: ending
noun: enemy
noun: energy
noun: enforcement
noun: engagement
noun: engine
noun: engineer
noun: engineering
noun: enjoyment
noun: enquiry
noun: enterprise
noun: entertainment
noun: enthusiasm
noun: enthusiast
noun: entitlement
noun: entity
noun: entrance
noun: entry
noun: envelope
noun: environment
noun: enzyme
noun: episode
noun: equality
noun: equation
noun: equilibrium
noun: equipment NUMBER=UNCOUNTABLE
noun: equity
noun: equivalent
noun: era
noun: erosion
noun: error
noun: escape
noun: essay
noun: essence
noun: establishment
noun: estate
noun: estimate
noun: ethics
noun: evaluation
noun: evening
noun: event
noun: evidence
noun: evil
noun: evolution
noun: exam
noun: examination
noun: example
noun: excavation
noun: exception
noun: excess
noun: exchange
noun: excitement
noun: exclusion
noun: excuse
noun: execution
noun: executive
noun: exemption
noun: exercise
noun: exhibition
noun: exile
noun: existence
noun: exit
noun: expansion
noun: expectation
noun: expedition
noun: expenditure
noun: expense
noun: experience
noun: experiment
noun: expert
noun: expertise
noun: explanation
noun: exploitation
noun: exploration
noun: explosion
noun: export
noun: exposure
noun: expression
noun: extension
noun: extent
noun: extract
noun: extreme
noun: eye
noun: eyebrow
noun: fabric
noun: facade
noun: face
noun: facility
noun: fact
noun: faction
noun: factor
noun: factory
noun: faculty
noun: failure
noun: fair
noun: fairy
noun: faith
noun: fall
noun: fame
noun: family
noun: fan
noun: fantasy
noun: fare
noun: farm
noun: farmer
noun: farming
noun: fashion
noun: fat
noun: fate
noun: father
noun: fault
noun: favour
noun: favourite
noun: fax
noun: fear
noun: feast
noun: feather
noun: feature
noun: federation
noun: fee
noun: feed
noun: feedback
noun: feel
noun: feeling
noun: fellow
noun: female
noun: feminist
noun: fence
noun: ferry
noun: fertility
noun: festival
noun: fever
noun: few
noun: fibre
noun: fiction
noun: field
noun: fig
noun: fight
noun: fighter
noun: figure
noun: file
noun: film
noun: filter
noun: final
noun: finance
noun: finding
noun: fine
noun: finger
noun: finish
noun: fire
noun: firm
noun: fish
noun: fisherman
noun: fishing
noun: fist
noun: fit
noun: fitness
noun: fitting
noun: fixture
noun: flag
noun: flame
noun: flash
noun: flat
noun: flavour
noun: fleet
noun: flesh
noun: flexibility
noun: flight
noun: flock
noun: flood
noun: floor
noun: flour
noun: flow
noun: flower
noun: fluctuation
noun: fluid
noun: fly
noun: focus
noun: fog
noun: fold
noun: folk
noun: follower
noun: food
noun: fool
noun: foot
noun: football
noun: footstep
noun: force
noun: forecast
noun: forehead
noun: foreigner
noun: forest
noun: forestry
noun: fork
noun: form
noun: format
noun: formation
noun: formula
noun: formulation
noun: fortnight
noun: fortune
noun: forum
noun: fossil
noun: foundation
noun: founder
noun: fountain
noun: fox
noun: fraction
noun: fragment
noun: frame
noun: framework
noun: franchise
noun: fraud
noun: freedom
noun: freight
noun: frequency
noun: fridge
noun: friend
noun: friendship
noun: fringe
noun: frog
noun: front
noun: frontier
noun: fruit
noun: frustration
noun: fuel
noun: fun
noun: function
noun: fund
noun: funding
noun: funeral
noun: fur
noun: furniture
noun: fury
noun: fusion
noun: fuss
noun: future
noun: gain
noun: galaxy
noun: gall
noun: gallery
noun: gallon
noun: game
noun: gang
noun: gap
noun: garage
noun: garden
noun: gardener
noun: garlic
noun: garment
noun: gas
noun: gate
noun: gathering
noun: gaze
noun: gear
noun: gender
noun: gene
noun: general
noun: generation
noun: genius
noun: gentleman
noun: geography
noun: gesture
noun: ghost
noun: giant
noun: gift
noun: gig
noun: girl
noun: girlfriend
noun: glance
noun: glass
noun: glimpse
noun: gloom
noun: glory
noun: glove
noun: glow
noun: go
noun: goal
noun: goalkeeper
noun: goat
noun: god
noun: gold
noun: golf
noun: good
noun: goodness
noun: gospel
noun: gossip
noun: government
noun: governor
noun: gown
noun: grace
noun: grade
noun: graduate
noun: grain
noun: grammar
noun: grandfather
noun: grandmother
noun: grant
noun: graph
noun: graphics
noun: grasp
noun: grass
noun: grave
noun: gravel
noun: gravity
noun: green
noun: greenhouse
noun: greeting
noun: grid
noun: grief
noun: grin
noun: grip
noun: ground
noun: group
noun: grouping
noun: growth
noun: guarantee
noun: guard
noun: guardian
noun: guerrilla
noun: guess
noun: guest
noun: guidance
noun: guide
noun: guideline
noun: guild
noun: guilt
noun: guitar
noun: gun
noun: gut
noun: guy
noun: habit
noun: habitat
noun: hair
noun: half
noun: hall
noun: halt
noun: ham
noun: hammer
noun: hand
noun: handful
noun: handicap
noun: handle
noun: handling
noun: happiness
noun: harbour
noun: hardship
noun: hardware
noun: harm
noun: harmony
noun: harvest
noun: hat
noun: hatred
noun: hay
noun: hazard
noun: head
noun: heading
noun: headline
noun: headmaster
noun: headquarters
noun: health
noun: heap
noun: hearing
noun: heart
noun: heat
noun: heating
noun: heaven
noun: hectare
noun: hedge
noun: heel
noun: height
noun: heir
noun: helicopter
noun: hell
noun: helmet
noun: help
noun: hemisphere
noun: hen
noun: herb
noun: herd
noun: heritage
noun: hero
noun: heroin
noun: hierarchy
noun: highlight
noun: highway
noun: hill
noun: hint
noun: hip
noun: hire
noun: historian
noun: history
noun: hit
noun: hobby
noun: hold
noun: holder
noun: holding
noun: hole
noun: holiday
noun: holly
noun: home
noun: homework
noun: honey
noun: honour
noun: hook
noun: hope
noun: horizon
noun: horn
noun: horror
noun: horse
noun: hospital
noun: hospitality
noun: host
noun: hostage
noun: hostility
noun: hotel
noun: hour
noun: house
noun: household
noun: housewife
noun: housing
noun: human
noun: humanity
noun: humour
noun: hunger
noun: hunt
noun: hunter
noun: hunting
noun: hurry
noun: husband
noun: hut
noun: hydrogen
noun: hypothesis
noun: ice
noun: idea
noun: ideal
noun: identification
noun: identity
noun: ideology
noun: ignorance
noun: illness
noun: illusion
noun: illustration
noun: image
noun: imagination
noun: immigrant
noun: immigration
noun: impact
noun: implementation
noun: implication
noun: import
noun: importance
noun: impression
noun: imprisonment
noun: improvement
noun: impulse
noun: inability
noun: incentive
noun: inch
noun: incidence
noun: incident
noun: inclusion
noun: income
noun: increase
noun: independence
noun: index
noun: indication
noun: indicator
noun: individual
noun: industry
noun: inequality
noun: infant
noun: infection
noun: inflation
noun: influence
noun: information
noun: infrastructure
noun: ingredient
noun: inhabitant
noun: inheritance
noun: inhibition
noun: initial
noun: initiative
noun: injection
noun: injunction
noun: injury
noun: inn
noun: innocence
noun: innovation
noun: input
noun: inquest
noun: inquiry
noun: insect
noun: inside
noun: insider
noun: insight
noun: insistence
noun: inspection
noun: inspector
noun: inspiration
noun: installation
noun: instance
noun: instant
noun: instinct
noun: institute
noun: institution
noun: instruction
noun: instructor
noun: instrument
noun: insurance
noun: intake
noun: integration
noun: integrity
noun: intellectual
noun: intelligence
noun: intensity
noun: intent
noun: intention
noun: interaction
noun: intercourse
noun: interest
noun: interface
noun: interference
noun: interior
noun: interpretation
noun: interval
noun: intervention
noun: interview
noun: introduction
noun: invasion
noun: invention
noun: investigation
noun: investigator
noun: investment
noun: investor
noun: invitation
noun: involvement
noun: ion
noun: iron
noun: irony
noun: island
noun: isolation
noun: issue
noun: item
noun: ivory
noun: jacket
noun: jail
noun: jam
noun: jar
noun: jaw
noun: jazz
noun: jeans
noun: jet
noun: jew
noun: jewel
noun: jewellery
noun: job
noun: jockey
noun: joint
noun: joke
noun: journal
noun: journalist
noun: journey
noun: joy
noun: judge
noun: judgement
noun: judgment
noun: juice
noun: jump
noun: junction
noun: jungle
noun: jurisdiction
noun: jury
noun: justice
noun: justification
noun: keeper
noun: kettle
noun: key
noun: keyboard
noun: kick
noun: kid
noun: kidney
noun: killer
noun: killing
noun: kilometre
noun: kind
noun: king
noun: kingdom
noun: kiss
noun: kit
noun: kitchen
noun: kite
noun: knee
noun: knife
noun: knight
noun: knitting
noun: knock
noun: knot
noun: knowledge
noun: lab
noun: label
noun: laboratory
noun: labour
noun: labourer
noun: lace
noun: lack
noun: lad
noun: ladder
noun: lady
noun: lake
noun: lamb
noun: lamp
noun: land
noun: landing
noun: landlord
noun: landowner
noun: landscape
noun: lane
noun: language
noun: lap
noun: laser
noun: laugh
noun: laughter
noun: launch
noun: law
noun: lawn
noun: lawyer
noun: layer
noun: layout
noun: lead
noun: leader
noun: leadership
noun: leaf
noun: leaflet
noun: league
noun: learner
noun: learning
noun: lease
noun: leather
noun: leave
noun: lecture
noun: lecturer
noun: left
noun: leg
noun: legacy
noun: legend
noun: legislation
noun: legislature
noun: leisure
noun: lemon
noun: lender
noun: length
noun: lesson
noun: letter
noun: level
noun: liability
noun: liaison
noun: liberal
noun: liberation
noun: liberty
noun: librarian
noun: library
noun: licence
noun: lid
noun: lie
noun: life
noun: lifespan
noun: lifestyle
noun: lifetime
noun: lift
noun: light
noun: lighting
noun: like
noun: likelihood
noun: limb
noun: limestone
noun: limit
noun: limitation
noun: line
noun: linen
noun: link
noun: lion
noun: lip
noun: liquid
noun: list
noun: listener
noun: literacy
noun: literature
noun: litigation
noun: litre
noun: liver
noun: living
noun: load
noun: loan
noun: lobby
noun: local
noun: locality
noun: location
noun: lock
noun: locomotive
noun: log
noun: logic
noun: look
noun: loop
noun: lord
noun: lordship
noun: lorry
noun: loss
noun: lot
noun: lounge
noun: love
noun: lover
noun: loyalty
noun: luck NUMBER=UNCOUNTABLE
noun: lump
noun: lunch
noun: lunchtime
noun: lung
noun: luxury
noun: machine
noun: machinery
noun: magazine
noun: magic
noun: magistrate
noun: magnitude
noun: maid
noun: mail NUMBER=UNCOUNTABLE
noun: mainframe
noun: mainland
noun: mains
noun: mainstream
noun: maintenance
noun: majesty
noun: majority
noun: make
noun: make-up NUMBER=UNCOUNTABLE
noun: maker
noun: making
noun: male
noun: mammal
noun: man
noun: management
noun: manager
noun: manifestation
noun: manipulation
noun: mankind
noun: manner
noun: manor
noun: manpower
noun: manual
noun: manufacture
noun: manufacturer
noun: manufacturing
noun: manuscript
noun: map
noun: marathon
noun: marble
noun: march
noun: margin
noun: mark
noun: marker
noun: market
noun: marketing
noun: marriage
noun: marsh
noun: mask
noun: mass
noun: master
noun: match
noun: mate
noun: material
noun: mathematics
noun: matrix
noun: matter
noun: maturity
noun: maximum
noun: mayor
noun: meadow
noun: meal
noun: meaning
noun: means
noun: meantime
noun: measure
noun: measurement
noun: meat
noun: mechanism
noun: medal
noun: media NUMBER=PLURAL
noun: medicine
noun: medium
noun: meeting
noun: member
noun: membership
noun: membrane
noun: memorandum
noun: memorial
noun: memory
noun: mention
noun: menu
noun: merchant
noun: mercy
noun: merger
noun: merit
noun: mess
noun: message
noun: metal
noun: metaphor
noun: method
noun: methodology
noun: metre
noun: microphone
noun: middle
noun: midfield
noun: midnight
noun: migration
noun: mile
noun: milk
noun: mill
noun: mind
noun: mine
noun: miner
noun: mineral
noun: minimum
noun: mining
noun: minister
noun: ministry
noun: minority
noun: minute
noun: miracle
noun: mirror
noun: misery
noun: missile
noun: mission
noun: mist
noun: mistake
noun: mistress
noun: mix
noun: mixture
noun: mobility
noun: mode
noun: model
noun: modification
noun: module
noun: mole
noun: molecule
noun: moment
noun: momentum
noun: monarch
noun: monarchy
noun: monastery
noun: money
noun: monitor
noun: monitoring
noun: monk
noun: monkey
noun: monopoly
noun: monster
noun: month
noun: monument
noun: mood
noun: moon
noun: moor
noun: moral
noun: morale
noun: morality
noun: morning
noun: mortality
noun: mortgage
noun: mosaic
noun: mother
noun: motif
noun: motion
noun: motivation
noun: motive
noun: motor
noun: motorist
noun: motorway
noun: mould
noun: mountain
noun: mouse
noun: mouth
noun: move
noun: movement
noun: movie
noun: mud
noun: mug
noun: multimedia
noun: murder
noun: murderer
noun: muscle
noun: museum
noun: mushroom
noun: music
noun: musician
noun: mutation
noun: mystery
noun: myth
noun: nail
noun: name
noun: narrative
noun: nation
noun: nationalism
noun: nationalist
noun: nationality
noun: native
noun: nature
noun: navy
noun: necessity
noun: neck
noun: need
noun: needle
noun: neglect
noun: negligence
noun: negotiation
noun: neighbour
noun: neighbourhood
noun: nephew
noun: nerve
noun: nest
noun: net
noun: network
noun: newcomer
noun: news
noun: newspaper
noun: night
noun: nightmare
noun: nitrogen
noun: node
noun: noise
noun: nomination
noun: nonsense
noun: norm
noun: north
noun: nose
noun: note
noun: notebook
noun: nothing
noun: notice
noun: notion
noun: noun
noun: novel
noun: novelist
noun: nucleus
noun: nuisance
noun: number
noun: nun
noun: nurse
noun: nursery
noun: nursing
noun: nut
noun: oak
noun: object
noun: objection
noun: objective
noun: obligation
noun: observation
noun: observer
noun: obstacle
noun: occasion
noun: occupation
noun: occurrence
noun: ocean
noun: odd
noun: odour
noun: offence
noun: offender
noun: offer
noun: offering
noun: office
noun: officer
noun: official
noun: offspring
noun: oil
noun: omission
noun: onion
noun: opening
noun: opera
noun: operating
noun: operation
noun: operator
noun: opinion
noun: opponent
noun: opportunity
noun: opposite
noun: opposition
noun: optimism
noun: option
noun: orange
noun: orbit
noun: orchestra
noun: order
noun: organ
noun: organisation
noun: organiser
noun: organism
noun: organization
noun: orientation
noun: origin
noun: original
noun: other
noun: outbreak
noun: outcome
noun: outfit
noun: outlet
noun: outline
noun: outlook
noun: output
noun: outset
noun: outside
noun: outsider
noun: oven
noun: over
noun: overall
noun: overview
noun: owl
noun: owner
noun: ownership
noun: oxygen
noun: ozone
noun: pace
noun: pack
noun: package
noun: packet
noun: pad
noun: page
noun: pain
noun: paint
noun: painter
noun: painting
noun: pair
noun: pal
noun: palace
noun: palm
noun: pan
noun: panel
noun: panic
noun: paper
noun: par
noun: parade
noun: paragraph
noun: parallel
noun: parameter
noun: parcel
noun: pardon
noun: parent
noun: parish
noun: park
noun: parking
noun: parliament
noun: part
noun: participant
noun: participation
noun: particle
noun: particular
noun: partner
noun: partnership
noun: party
noun: pass
noun: passage
noun: passenger
noun: passion
noun: passport
noun: past
noun: pasture
noun: patch
noun: patent
noun: path
noun: patience
noun: patient
noun: patrol
noun: patron
noun: pattern
noun: pause
noun: pavement
noun: pay
noun: payment
noun: peace
noun: peak
noun: peasant
noun: pedestrian
noun: peer
noun: pen
noun: penalty
noun: pencil
noun: penny
noun: pension
noun: pensioner
noun: people
noun: pepper
noun: percent
noun: percentage
noun: perception
noun: performance
noun: performer
noun: period
noun: permission
noun: person
noun: personality
noun: personnel
noun: perspective
noun: pest
noun: pet
noun: petition
noun: petrol
noun: phase
noun: phenomenon
noun: philosopher
noun: philosophy
noun: phone
noun: photo
noun: photograph
noun: photographer
noun: photography
noun: phrase
noun: physician
noun: physics
noun: piano
noun: picture
noun: pie
noun: piece
noun: pier
noun: pig
noun: pigeon
noun: pile
noun: pill
noun: pillar
noun: pillow
noun: pilot
noun: pin
noun: pine
noun: pint
noun: pioneer
noun: pipe
noun: pit
noun: pitch
noun: pity
noun: place
noun: placement
noun: plain
noun: plaintiff
noun: plan
noun: plane
noun: planet
noun: planner
noun: planning
noun: plant
noun: plasma
noun: plaster
noun: plastic
noun: plate
noun: platform
noun: play
noun: player
noun: plea
noun: pleasure
noun: plot
noun: pocket
noun: poem
noun: poet
noun: poetry
noun: point
noun: poison
noun: pole
noun: police
noun: policeman
noun: policy
noun: politician
noun: politics
noun: poll
noun: pollution
noun: polymer
noun: polytechnic
noun: pond
noun: pony
noun: pool
noun: pop
noun: pope
noun: popularity
noun: population
noun: port
noun: porter
noun: portfolio
noun: portion
noun: portrait
noun: position
noun: possession
noun: possibility
noun: post
noun: postcard
noun: poster
noun: pot
noun: potato
noun: potential
noun: pottery
noun: pound
noun: poverty
noun: powder
noun: power
noun: practice
noun: practitioner
noun: praise
noun: prayer
noun: precaution
noun: precedent
noun: precision
noun: predator
noun: predecessor
noun: prediction
noun: preference
noun: pregnancy
noun: prejudice
noun: premise
noun: premium
noun: preoccupation
noun: preparation
noun: prescription
noun: presence
noun: present
noun: presentation
noun: preservation
noun: presidency
noun: president
noun: press
noun: pressure
noun: prestige
noun: prevalence
noun: prevention
noun: prey
noun: price
noun: pride
noun: priest
noun: primary
noun: prince
noun: princess
noun: principal
noun: principle
noun: print
noun: printer
noun: printing
noun: priority
noun: prison
noun: prisoner
noun: privacy
noun: privatisation
noun: privatization
noun: privilege
noun: prize
noun: probability
noun: probe
noun: problem
noun: procedure
noun: proceed
noun: proceeding
noun: process
noun: processing
noun: procession
noun: processor
noun: produce
noun: producer
noun: product
noun: production
noun: productivity
noun: profession
noun: professional
noun: professor
noun: profile
noun: profit
noun: profitability
noun: program
noun: programme
noun: programming
noun: progress
noun: project
noun: projection
noun: promise
noun: promoter
noun: promotion
noun: proof
noun: propaganda
noun: property
noun: proportion
noun: proposal
noun: proposition
noun: proprietor
noun: prosecution
noun: prospect
noun: prosperity
noun: protection
noun: protein
noun: protest
noun: protocol
noun: provider
noun: province
noun: provision
noun: psychologist
noun: psychology
noun: pub
noun: public
noun: publication
noun: publicity
noun: publisher
noun: publishing
noun: pudding
noun: pulse
noun: pump
noun: punch
noun: punishment
noun: pupil
noun: purchase
noun: purchaser
noun: purpose
noun: pursuit
noun: push
noun: qualification
noun: quality
noun: quantity
noun: quantum
noun: quarry
noun: quarter
noun: queen
noun: query
noun: quest
noun: question
noun: questionnaire
noun: queue
noun: quid
noun: quota
noun: quotation
noun: rabbit
noun: race
noun: racism
noun: rack
noun: radiation
noun: radical
noun: radio
noun: rage
noun: raid
noun: rail
noun: railway
noun: rain
noun: rally
noun: ram
noun: range
noun: rank
noun: rape
noun: rat
noun: rate
noun: rating
noun: ratio
noun: ray
noun: reach
noun: reaction
noun: reactor
noun: reader
noun: reading
noun: realism
noun: reality
noun: realm
noun: rear
noun: reason
noun: reasoning
noun: rebel
noun: rebellion
noun: receipt
noun: receiver
noun: reception
noun: receptor
noun: recession
noun: recipe
noun: recipient
noun: recognition
noun: recommendation
noun: reconstruction
noun: record
noun: recorder
noun: recording
noun: recovery
noun: recreation
noun: recruit
noun: recruitment
noun: red
noun: reduction
noun: redundancy
noun: referee
noun: reference
noun: referendum
noun: referral
noun: reflection
noun: reform
noun: reformer
noun: refuge
noun: refugee
noun: refusal
noun: regard
noun: regime
noun: regiment
noun: region
noun: register
noun: registration
noun: regret
noun: regulation
noun: rehabilitation
noun: rehearsal
noun: reign
noun: rejection
noun: relate
noun: relation
noun: relationship
noun: relative
noun: relaxation
noun: release
noun: relevance
noun: reliance
noun: relief
noun: religion
noun: reluctance
noun: remain
noun: remainder
noun: remark
noun: remedy
noun: reminder
noun: removal
noun: renaissance
noun: renewal
noun: rent
noun: repair
noun: repayment
noun: repetition
noun: replacement
noun: reply
noun: report
noun: reporter
noun: representation
noun: representative
noun: reproduction
noun: republic
noun: republican
noun: reputation
noun: request
noun: requirement
noun: rescue
noun: research
noun: researcher
noun: resentment
noun: reservation
noun: reserve
noun: reservoir
noun: residence
noun: resident
noun: residue
noun: resignation
noun: resistance
noun: resolution
noun: resort
noun: resource
noun: respect
noun: respondent
noun: response
noun: responsibility
noun: rest
noun: restaurant
noun: restoration
noun: restraint
noun: restriction
noun: result
noun: retailer
noun: retention
noun: retirement
noun: retreat
noun: return
noun: revelation
noun: revenge
noun: revenue
noun: reverse
noun: review
noun: revision
noun: revival
noun: revolution
noun: reward
noun: rhetoric
noun: rhythm
noun: rib
noun: ribbon
noun: rice
noun: ride
noun: rider
noun: ridge
noun: rifle
noun: right
noun: ring
noun: riot
noun: rise
noun: risk
noun: ritual
noun: rival
noun: river
noun: road
noun: robbery
noun: rock
noun: rocket
noun: rod
noun: role
noun: roll
noun: romance
noun: roof
noun: room
noun: root
noun: rope
noun: rose
noun: rotation
noun: round
noun: route
noun: routine
noun: row
noun: royalty
noun: rubbish
noun: rug
noun: rugby
noun: ruin
noun: rule
noun: ruler
noun: ruling
noun: rumour
noun: run
noun: runner
noun: rush
noun: sack
noun: sacrifice
noun: safety
noun: sail
noun: sailor
noun: saint
noun: sake
noun: salad
noun: salary
noun: sale
noun: salmon
noun: salon
noun: salt
noun: salvation
noun: sample
noun: sanction
noun: sanctuary
noun: sand NUMBER=UNCOUNTABLE
noun: sandwich
noun: satellite
noun: satisfaction NUMBER=UNCOUNTABLE
noun: sauce
noun: sausage
noun: saving
noun: saying
noun: scale
noun: scandal
noun: scenario
noun: scene
noun: scent
noun: schedule
noun: scheme
noun: scholar
noun: scholarship
noun: school
noun: science
noun: scientist
noun: scope
noun: score
noun: scrap
noun: scream
noun: screen
noun: screening
noun: screw
noun: script
noun: scrutiny
noun: sculpture
noun: sea
noun: seal
noun: search
noun: season
noun: seat
noun: second
noun: secret
noun: secretary
noun: secretion
noun: section
noun: sector
noun: security
noun: sediment
noun: seed
noun: segment
noun: selection
noun: self
noun: seller
noun: semi-final
noun: seminar
noun: senate
noun: senior
noun: sensation
noun: sense
noun: sensitivity
noun: sentence
noun: sentiment
noun: separation
noun: sequence
noun: sergeant
noun: series
noun: serum
noun: servant
noun: server
noun: service
noun: session
noun: set
noun: setting
noun: settlement
noun: sex
noun: sexuality
noun: shade
noun: shadow
noun: shaft
noun: shame
noun: shape
noun: share
noun: shareholder
noun: shed
noun: sheep
noun: sheet
noun: shelf
noun: shell
noun: shelter
noun: shield
noun: shift
noun: shilling
noun: ship
noun: shirt
noun: shit
noun: shock
noun: shoe
noun: shop
noun: shopping
noun: shore
noun: short
noun: shortage
noun: shot
noun: shoulder
noun: shout
noun: show
noun: shower
noun: shrub
noun: sick
noun: sickness
noun: side
noun: siege
noun: sigh
noun: sight
noun: sign
noun: signal
noun: signature
noun: significance
noun: silence
noun: silk
noun: silver
noun: similarity
noun: simplicity
noun: sin
noun: singer
noun: single
noun: sink
noun: sir
noun: sister
noun: site
noun: situation
noun: size
noun: skeleton
noun: sketch
noun: ski
noun: skill
noun: skin
noun: skipper
noun: skirt
noun: skull
noun: sky
noun: slab
noun: slave
noun: sleep
noun: sleeve
noun: slice
noun: slide
noun: slip
noun: slogan
noun: slope
noun: slot
noun: smell
noun: smile
noun: smoke
noun: snake
noun: snow
noun: soap
noun: soccer
noun: socialism
noun: socialist
noun: society
noun: sociology
noun: sock
noun: socket
noun: sodium
noun: sofa
noun: software
noun: soil
noun: soldier
noun: solicitor
noun: solidarity
noun: solo
noun: solution
noun: solvent
noun: son
noun: song
noun: sort
noun: soul
noun: sound
noun: soup
noun: source
noun: south
noun: sovereignty
noun: space
noun: speaker
noun: specialist
noun: species
noun: specification
noun: specimen
noun: spectacle
noun: spectator
noun: spectrum
noun: speculation
noun: speech
noun: speed
noun: spell
noun: spelling
noun: spending
noun: sphere
noun: spider
noun: spine
noun: spirit
noun: spite
noun: split
noun: spokesman
noun: sponsor
noun: sponsorship
noun: spoon
noun: sport
noun: spot
noun: spouse
noun: spray
noun: spread
noun: spring
noun: spy
noun: squad
noun: squadron
noun: square
noun: stability
noun: stable
noun: stadium
noun: staff
noun: stage
noun: stair
noun: staircase
noun: stake
noun: stall
noun: stamp
noun: stance
noun: stand
noun: standard
noun: standing
noun: star
noun: start
noun: state
noun: statement
noun: station
noun: statistics
noun: statue
noun: status
noun: statute
noun: stay
noun: steam
noun: steel
noun: stem
noun: step
noun: steward
noun: stick
noun: stimulation
noun: stimulus
noun: stitch
noun: stock
noun: stocking
noun: stomach
noun: stone
noun: stool
noun: stop
noun: storage
noun: store
noun: storm
noun: story
noun: strain
noun: strand
noun: stranger
noun: strap
noun: strategy
noun: straw
noun: stream
noun: street
noun: strength
noun: stress
noun: stretch
noun: strike
noun: striker
noun: string
noun: strip
noun: stroke
noun: structure
noun: struggle
noun: student
noun: studio
noun: study
noun: stuff
noun: style
noun: subject
noun: submission
noun: subscription
noun: subsidiary
noun: subsidy
noun: substance
noun: substitute
noun: suburb
noun: success
noun: succession
noun: successor
noun: sufferer
noun: suffering
noun: sugar
noun: suggestion
noun: suicide
noun: suit
noun: suitcase
noun: suite
noun: sulphur
noun: sum
noun: summary
noun: summer
noun: summit
noun: sun
noun: sunlight
noun: sunshine
noun: superintendent
noun: supermarket
noun: supervision
noun: supervisor
noun: supper
noun: supplement
noun: supplier
noun: supply
noun: support
noun: supporter
noun: surface
noun: surgeon
noun: surgery
noun: surplus
noun: surprise
noun: surrounding
noun: survey
noun: surveyor
noun: survival
noun: survivor
noun: suspect
noun: suspension
noun: suspicion
noun: sweat
noun: sweet
noun: swimming
noun: swing
noun: switch
noun: sword
noun: syllable
noun: symbol
noun: symmetry
noun: sympathy
noun: symptom
noun: syndrome
noun: synthesis
noun: system
noun: t-shirt
noun: table
noun: tablet
noun: tactic
noun: tail
noun: takeover
noun: tale
noun: talent
noun: talk
noun: talking
noun: tank
noun: tap
noun: tape
noun: target
noun: tariff
noun: task
noun: taste
noun: tax
noun: taxation
noun: taxi
noun: taxpayer
noun: tea
noun: teacher
noun: teaching
noun: team
noun: tear
noun: technique
noun: technology
noun: teenager
noun: telecommunication
noun: telephone
noun: television
noun: telly
noun: temper
noun: temperature
noun: temple
noun: temptation
noun: tenant
noun: tendency
noun: tennis
noun: tension
noun: tent
noun: term
noun: terminal
noun: terms
noun: terrace
noun: territory
noun: terror
noun: terrorist
noun: test
noun: testament
noun: testing
noun: text
noun: textbook
noun: textile
noun: texture
noun: thanks
noun: theatre
noun: theft
noun: theme
noun: theology
noun: theorist
noun: theory
noun: therapist
noun: therapy
noun: thesis
noun: thief
noun: thigh
noun: thing
noun: thinking
noun: thought
noun: thread
noun: threat
noun: threshold
noun: throat
noun: throne
noun: thrust
noun: thumb
noun: ticket
noun: tide
noun: tie
noun: tiger
noun: tile
noun: timber
noun: time
noun: timetable
noun: timing
noun: tin
noun: tip
noun: tissue
noun: title
noun: toast
noun: tobacco
noun: toe
noun: toilet
noun: toll
noun: tomato
noun: ton
noun: tone
noun: tongue
noun: tonne
noun: tool
noun: tooth
noun: top
noun: topic
noun: torch
noun: total
noun: touch
noun: tour
noun: tourism
noun: tourist
noun: tournament
noun: towel
noun: tower
noun: town
noun: toy
noun: trace
noun: track
noun: tract
noun: trade
noun: trader
noun: trading
noun: tradition
noun: traffic
noun: tragedy
noun: trail
noun: train
noun: trainee
noun: trainer
noun: training
noun: trait
noun: transaction
noun: transcription
noun: transfer
noun: transformation
noun: transition
noun: translation
noun: transmission
noun: transport
noun: trap
noun: travel
noun: traveller
noun: tray
noun: treasure
noun: treasurer
noun: treasury
noun: treat
noun: treatment
noun: treaty
noun: tree
noun: trench
noun: trend
noun: trial
noun: triangle
noun: tribe
noun: tribunal
noun: tribute
noun: trick
noun: trip
noun: triumph
noun: trolley
noun: troop
noun: trophy
noun: trouble
noun: trouser
noun: truck
noun: trunk
noun: trust
noun: trustee
noun: truth
noun: try
noun: tube
noun: tumour
noun: tune
noun: tunnel
noun: turkey
noun: turn
noun: turnover
noun: tutor
noun: twin
noun: twist
noun: type
noun: tyre
noun: ulcer
noun: umbrella
noun: uncertainty
noun: uncle
noun: understanding
noun: undertaking
noun: unemployment
noun: uniform
noun: union
noun: unionist
noun: unit
noun: unity
noun: universe
noun: university
noun: unrest
noun: upstairs
noun: urge
noun: urgency
noun: urine
noun: usage
noun: use
noun: user
noun: utility
noun: utterance
noun: vacuum
noun: validity
noun: valley
noun: valuation
noun: value
noun: valve
noun: van
noun: variable
noun: variant
noun: variation
noun: variety
noun: vat
noun: vector
noun: vegetable
noun: vegetation
noun: vehicle
noun: vein
noun: velocity
noun: velvet
noun: vendor
noun: venture
noun: venue
noun: verb
noun: verdict
noun: verse
noun: version
noun: vessel
noun: veteran
noun: vicar
noun: vice-president
noun: victim
noun: victory
noun: video
noun: view
noun: viewer
noun: viewpoint
noun: villa
noun: village
noun: villager
noun: violation
noun: violence
noun: virgin
noun: virtue
noun: virus
noun: vision
noun: visit
noun: visitor
noun: vitamin
noun: vocabulary
noun: voice
noun: voltage
noun: volume
noun: volunteer
noun: vote
noun: voter
noun: voucher
noun: voyage
noun: wage
noun: wagon
noun: waist
noun: waiter
noun: waiting
noun: wake
noun: walk
noun: walker
noun: wall
noun: want
noun: war
noun: ward
noun: wardrobe
noun: warehouse
noun: warmth
noun: warning
noun: warrant
noun: warranty
noun: warrior
noun: wartime
noun: wash
noun: washing
noun: waste
noun: watch
noun: water NUMBER=UNCOUNTABLE
noun: wave
noun: way
noun: weakness
noun: wealth
noun: weapon
noun: weather
noun: wedding
noun: weed
noun: week
noun: weekend
noun: weight
noun: welcome
noun: welfare
noun: well
noun: west
noun: whale
noun: wheat
noun: wheel
noun: while
noun: whip
noun: whisky
noun: whisper
noun: white
noun: whole
noun: wicket
noun: widow
noun: width
noun: wife
noun: wildlife
noun: will
noun: willingness
noun: win
noun: wind
noun: window
noun: wine
noun: wing
noun: winner
noun: winter
noun: wire
noun: wisdom
noun: wish
noun: wit
noun: witch
noun: withdrawal
noun: witness
noun: wolf
noun: woman
noun: wonder
noun: wood
noun: woodland
noun: wool
noun: word
noun: wording
noun: work
noun: worker
noun: workforce
noun: working
noun: workplace
noun: works
noun: workshop
noun: workstation
noun: world
noun: worm
noun: worry
noun: worship
noun: worth
noun: wound
noun: wrist
noun: writer
noun: writing
noun: wrong
noun: x-ray
noun: yacht
noun: yard
noun: yarn
noun: year
noun: yield
noun: youngster
noun: youth
noun: zone
noun: anybody
noun: anyone
noun: anything
noun: everybody
noun: everyone
noun: everything
noun: nobody
noun: somebody
noun: someone
noun: something

preposition: about
preposition: above
preposition: according to
preposition: across
preposition: after
preposition: against
preposition: aged
preposition: along
preposition: alongside
preposition: amid
preposition: among
preposition: amongst
preposition: around
preposition: as
preposition: at
preposition: before
preposition: behind
preposition: below
preposition: beneath
preposition: beside
preposition: besides
preposition: between
preposition: beyond
preposition: by
preposition: concerning
preposition: considering
preposition: despite
preposition: down
preposition: during
preposition: except
preposition: following
preposition: for
preposition: from
preposition: in
preposition: including
preposition: inside
preposition: into
preposition: like
preposition: near
preposition: of
preposition: off
preposition: on
preposition: onto
preposition: out
preposition: outside
preposition: over
preposition: past
preposition: per
preposition: regarding
preposition: round
preposition: since
preposition: through
preposition: throughout
preposition: till
preposition: to
preposition: toward
preposition: towards
preposition: under
preposition: underneath
preposition: unlike
preposition: until
preposition: up
preposition: upon
preposition: versus
preposition: via
preposition: with WITH=YES
preposition: within
preposition: without

pronoun: I ROLE?SUBJECT PERSON=FIRST NUMBER=SINGULAR
pronoun: you PERSON=SECOND
pronoun: he ROLE?SUBJECT PERSON=THIRD NUMBER=SINGULAR
pronoun: she ROLE?SUBJECT PERSON=THIRD NUMBER=SINGULAR
pronoun: it PERSON=THIRD NUMBER=SINGULAR
pronoun: no-one PERSON=THIRD NUMBER=SINGULAR
pronoun: one ROLE?SUBJECT PERSON=THIRD NUMBER=SINGULAR
pronoun: who ROLE?SUBJECT PERSON=THIRD NUMBER=SINGULAR STYPE=QUESTION
pronoun: we ROLE?SUBJECT PERSON=FIRST PERSON=FIRST NUMBER=PLURAL
pronoun: they ROLE?SUBJECT PERSON=THIRD NUMBER=PLURAL

pronoun: me ROLE?OBJECT
pronoun: him ROLE?OBJECT
pronoun: her ROLE?OBJECT
pronoun: us ROLE?OBJECT
pronoun: them ROLE?OBJECT
pronoun: whom ROLE?OBJECT

pronoun: mine PERSON=THIRD
pronoun: ours PERSON=THIRD
pronoun: theirs PERSON=THIRD
pronoun: yours PERSON=THIRD
pronoun: none PERSON=THIRD NUMBER=PLURAL
pronoun: whoever PERSON=THIRD NUMBER=SINGULAR

pronoun: myself ROLE?OBJECT AGENT.PERSON=FIRST AGENT.NUMBER=SINGULAR
pronoun: yourself ROLE?OBJECT AGENT.PERSON=SECOND AGENT.NUMBER=SINGULAR
pronoun: himself ROLE?OBJECT AGENT.PERSON=THIRD AGENT.NUMBER=SINGULAR
pronoun: herself ROLE?OBJECT AGENT.PERSON=THIRD AGENT.NUMBER=SINGULAR
pronoun: itself ROLE?OBJECT AGENT.PERSON=THIRD AGENT.NUMBER=SINGULAR
pronoun: ourselves ROLE?OBJECT AGENT.PERSON=FIRST AGENT.NUMBER=PLURAL
pronoun: yourselves ROLE?OBJECT AGENT.PERSON=SECOND AGENT.NUMBER=PLURAL
pronoun: each other ROLE?OBJECT AGENT.NUMBER=PLURAL
pronoun: one another ROLE?OBJECT AGENT.NUMBER=PLURAL
pronoun: themselves ROLE?OBJECT AGENT.PERSON=THIRD AGENT.NUMBER=PLURAL

verb: abandon ROLE?OBJECT
verb: abolish ROLE?OBJECT
verb: absorb ROLE?OBJECT
verb: abuse ROLE?OBJECT
verb: accelerate
verb: accept ROLE?OBJECT
verb: access ROLE?OBJECT
verb: accommodate ROLE?OBJECT
verb: accompany ROLE?OBJECT
verb: accomplish ROLE?OBJECT
verb: accord ROLE!OBJECT
verb: account ROLE?OBJECT
verb: accumulate
verb: accuse ROLE?OBJECT
verb: achieve
verb: acknowledge ROLE?OBJECT
verb: acquire ROLE?OBJECT
verb: act ROLE!OBJECT
verb: activate ROLE?OBJECT
verb: adapt
verb: add ROLE?OBJECT
verb: address ROLE?OBJECT
verb: adjust
verb: administer ROLE?OBJECT
verb: admire ROLE?OBJECT
verb: admit ROLE?OBJECT
verb: adopt ROLE?OBJECT
verb: advance
verb: advertise
verb: advise ROLE?OBJECT
verb: advocate ROLE?OBJECT
verb: affect ROLE?OBJECT
verb: afford ROLE?OBJECT
verb: age ROLE!OBJECT
verb: agree
verb: aid ROLE?OBJECT
verb: aim
verb: alarm ROLE?OBJECT
verb: alert ROLE?OBJECT
verb: allege ROLE?OBJECT
verb: allocate ROLE?OBJECT
verb: allow ROLE?OBJECT
verb: alter ROLE?OBJECT
verb: amend ROLE?OBJECT
verb: amount ROLE?OBJECT
verb: amuse ROLE?OBJECT
verb: analyse ROLE?OBJECT
verb: anger
verb: announce ROLE?OBJECT
verb: annoy
verb: answer
verb: anticipate ROLE!OBJECT
verb: apologise ROLE!OBJECT
verb: appeal ROLE!OBJECT
verb: appear ROLE!OBJECT
verb: apply
verb: appoint ROLE?OBJECT
verb: appreciate ROLE?OBJECT
verb: approach
verb: approve
verb: argue ROLE!OBJECT
verb: arise ROLE!OBJECT
verb: arm
verb: arouse ROLE?OBJECT
verb: arrange ROLE?OBJECT
verb: arrest ROLE?OBJECT
verb: arrive ROLE!OBJECT
verb: articulate ROLE?OBJECT
verb: ascertain ROLE?OBJECT
verb: ask ROLE?OBJECT
verb: assault ROLE?OBJECT
verb: assemble
verb: assert ROLE?OBJECT
verb: assess ROLE?OBJECT
verb: assign ROLE?OBJECT
verb: assist ROLE?OBJECT
verb: associate ROLE?OBJECT
verb: assume ROLE?OBJECT
verb: assure ROLE?OBJECT
verb: attach ROLE?OBJECT
verb: attack
verb: attain ROLE?OBJECT
verb: attempt ROLE?OBJECT
verb: attend ROLE?OBJECT
verb: attract ROLE?OBJECT
verb: attribute ROLE?OBJECT
verb: authorise ROLE?OBJECT
verb: avoid ROLE?OBJECT
verb: await ROLE?OBJECT
verb: awake
verb: awaken ROLE?OBJECT
verb: award ROLE?OBJECT
verb: back ROLE?OBJECT
verb: bake ROLE?OBJECT
verb: balance
verb: ban ROLE?OBJECT
verb: bang ROLE?OBJECT
verb: bar ROLE?OBJECT
verb: bargain ROLE!OBJECT
verb: base ROLE?OBJECT
verb: battle
verb: bear ROLE?OBJECT
verb: beat ROLE?OBJECT
verb: become ROLE?OBJECT
verb: beg ROLE!OBJECT
verb: begin
verb: behave ROLE!OBJECT
verb: believe
verb: belong ROLE!OBJECT
verb: bend
verb: benefit
verb: bet ROLE?OBJECT
verb: betray ROLE?OBJECT
verb: bid
verb: bind ROLE?OBJECT
verb: bite
verb: blame ROLE?OBJECT
verb: blast ROLE?OBJECT
verb: bleed ROLE!OBJECT
verb: bless ROLE?OBJECT
verb: blink
verb: block ROLE?OBJECT
verb: blow
verb: board ROLE?OBJECT
verb: boast ROLE!OBJECT
verb: boil
verb: bomb ROLE?OBJECT
verb: book ROLE?OBJECT
verb: boost ROLE?OBJECT
verb: borrow ROLE?OBJECT
verb: bother ROLE?OBJECT
verb: bounce
verb: bow
verb: bowl
verb: break
verb: breathe
verb: breed
verb: bring ROLE?OBJECT
verb: broadcast ROLE?OBJECT
verb: brush ROLE?OBJECT
verb: build ROLE?OBJECT
verb: bump
verb: burn
verb: burst
verb: bury ROLE?OBJECT
verb: buy ROLE?OBJECT
verb: calculate
verb: call
verb: calm ROLE?OBJECT
verb: campaign
verb: cancel ROLE?OBJECT
verb: capture ROLE?OBJECT
verb: care ROLE!OBJECT
verb: carry ROLE?OBJECT
verb: carve ROLE?OBJECT
verb: cast ROLE?OBJECT
verb: catch ROLE?OBJECT
verb: cater for ROLE?OBJECT
verb: cause ROLE?OBJECT
verb: cease
verb: celebrate
verb: centre ROLE?OBJECT
verb: chair ROLE?OBJECT
verb: challenge ROLE?OBJECT
verb: change
verb: characterise ROLE?OBJECT
verb: charge
verb: chase ROLE?OBJECT
verb: chat ROLE!OBJECT
verb: check
verb: cheer
verb: chew
verb: choke
verb: choose
verb: chop ROLE?OBJECT
verb: circulate ROLE?OBJECT
verb: cite ROLE?OBJECT
verb: claim ROLE?OBJECT
verb: clarify ROLE?OBJECT
verb: classify ROLE?OBJECT
verb: clean ROLE?OBJECT
verb: clear ROLE?OBJECT
verb: climb ROLE?OBJECT
verb: cling to ROLE?OBJECT
verb: close ROLE?OBJECT
verb: clutch ROLE?OBJECT
verb: co-operate with ROLE?OBJECT
verb: coach ROLE?OBJECT
verb: code ROLE?OBJECT
verb: coincide with ROLE?OBJECT
verb: collapse
verb: collect ROLE?OBJECT
verb: colour ROLE?OBJECT
verb: combat ROLE?OBJECT
verb: combine ROLE?OBJECT
verb: come ROLE!OBJECT
verb: comfort ROLE?OBJECT
verb: command
verb: commence
verb: comment ROLE!OBJECT
verb: comment on ROLE?OBJECT
verb: commission ROLE?OBJECT
verb: commit ROLE?OBJECT
verb: communicate ROLE!OBJECT
verb: compare ROLE?OBJECT
verb: compel ROLE?OBJECT
verb: compensate ROLE?OBJECT
verb: compete ROLE!OBJECT
verb: compete PREP?WITH
verb: compile ROLE?OBJECT
verb: complain ROLE!OBJECT
verb: complement ROLE?OBJECT
verb: complete ROLE?OBJECT
verb: complicate ROLE?OBJECT
verb: comply
verb: compose ROLE?OBJECT
verb: compound ROLE?OBJECT
verb: comprise ROLE?OBJECT
verb: compromise
verb: compute
verb: conceal ROLE?OBJECT
verb: concede ROLE?OBJECT
verb: conceive
verb: concentrate
verb: concern ROLE?OBJECT
verb: conclude ROLE?OBJECT
verb: condemn ROLE?OBJECT
verb: conduct ROLE?OBJECT
verb: confer ROLE?OBJECT
verb: confess
verb: confine ROLE?OBJECT
verb: confirm ROLE?OBJECT
verb: conflict
verb: conform
verb: confront ROLE?OBJECT
verb: confuse ROLE?OBJECT
verb: congratulate ROLE?OBJECT
verb: connect ROLE?OBJECT
verb: consider ROLE?OBJECT
verb: consist
verb: consolidate ROLE?OBJECT
verb: constitute ROLE?OBJECT
verb: constrain ROLE?OBJECT
verb: construct ROLE?OBJECT
verb: consult ROLE?OBJECT
verb: consume ROLE?OBJECT
verb: contact ROLE?OBJECT
verb: contain ROLE?OBJECT
verb: contemplate ROLE?OBJECT
verb: contend
verb: contest ROLE?OBJECT
verb: continue ROLE?OBJECT
verb: contract ROLE!OBJECT
verb: contrast ROLE?OBJECT
verb: contribute ROLE?OBJECT
verb: control ROLE?OBJECT
verb: convert ROLE?OBJECT
verb: convey ROLE?OBJECT
verb: convict ROLE?OBJECT
verb: convince ROLE?OBJECT
verb: cook
verb: cool ROLE?OBJECT
verb: coordinate ROLE?OBJECT
verb: cop ROLE?OBJECT
verb: cope
verb: copy ROLE?OBJECT
verb: correct ROLE?OBJECT
verb: correspond
verb: cost ROLE?OBJECT
verb: cough
verb: count
verb: counter ROLE?OBJECT
verb: couple
verb: cover ROLE?OBJECT
verb: crack
verb: crash
verb: crawl
verb: create ROLE?OBJECT
verb: credit ROLE?OBJECT
verb: creep
verb: criticise
verb: crop ROLE?OBJECT
verb: cross ROLE?OBJECT
verb: crouch
verb: crowd ROLE?OBJECT
verb: crush
verb: cry
verb: cultivate ROLE?OBJECT
verb: curl
verb: curve ROLE?OBJECT
verb: cut ROLE?OBJECT
verb: damage ROLE?OBJECT
verb: damn ROLE?OBJECT
verb: dance
verb: dare
verb: dash
verb: date ROLE?OBJECT
verb: deal ROLE?OBJECT
verb: debate
verb: decide
verb: declare ROLE?OBJECT
verb: decline
verb: decorate ROLE?OBJECT
verb: decrease
verb: dedicate ROLE?OBJECT
verb: deem ROLE?OBJECT
verb: defeat
verb: defend ROLE?OBJECT
verb: define ROLE?OBJECT
verb: defy ROLE?OBJECT
verb: delay
verb: delete ROLE?OBJECT
verb: delight
verb: deliver
verb: demand ROLE?OBJECT
verb: demolish ROLE?OBJECT
verb: demonstrate
verb: denounce ROLE?OBJECT
verb: deny ROLE?OBJECT
verb: depart
verb: depend
verb: depict ROLE?OBJECT
verb: deploy ROLE?OBJECT
verb: deposit ROLE?OBJECT
verb: deprive ROLE?OBJECT
verb: derive ROLE?OBJECT
verb: descend
verb: describe ROLE?OBJECT
verb: desert
verb: deserve ROLE?OBJECT
verb: design ROLE?OBJECT
verb: designate ROLE?OBJECT
verb: desire ROLE?OBJECT
verb: destroy
verb: detain ROLE?OBJECT
verb: detect ROLE?OBJECT
verb: deter ROLE?OBJECT
verb: deteriorate
verb: determine ROLE?OBJECT
verb: develop
verb: devise ROLE?OBJECT
verb: devote ROLE?OBJECT
verb: diagnose ROLE?OBJECT
verb: dictate ROLE?OBJECT
verb: die
verb: differ
verb: differentiate ROLE?OBJECT
verb: dig
verb: diminish ROLE?OBJECT
verb: dine
verb: dip
verb: direct
verb: disagree
verb: disappear
verb: disappoint
verb: discard ROLE?OBJECT
verb: discharge ROLE?OBJECT
verb: discipline ROLE?OBJECT
verb: disclose ROLE?OBJECT
verb: discount ROLE?OBJECT
verb: discourage ROLE?OBJECT
verb: discover ROLE?OBJECT
verb: discuss ROLE?OBJECT
verb: disguise ROLE?OBJECT
verb: dislike ROLE?OBJECT
verb: dismiss ROLE?OBJECT
verb: disperse
verb: display ROLE?OBJECT
verb: dispose
verb: dispute ROLE?OBJECT
verb: disrupt ROLE?OBJECT
verb: dissolve
verb: distinguish ROLE?OBJECT
verb: distort
verb: distract ROLE?OBJECT
verb: distribute ROLE?OBJECT
verb: disturb ROLE?OBJECT
verb: dive
verb: divert ROLE?OBJECT
verb: divide ROLE?OBJECT
verb: divorce
verb: document ROLE?OBJECT
verb: dominate
verb: donate ROLE?OBJECT
verb: double
verb: doubt ROLE?OBJECT
verb: draft ROLE?OBJECT
verb: drag ROLE?OBJECT
verb: drain
verb: draw
verb: dream
verb: dress
verb: drift
verb: drill
verb: drink
verb: drive
verb: drop
verb: drown
verb: drug ROLE?OBJECT
verb: dry
verb: dump ROLE?OBJECT
verb: earn ROLE?OBJECT
verb: ease ROLE?OBJECT
verb: eat
verb: echo
verb: edit ROLE?OBJECT
verb: educate ROLE?OBJECT
verb: effect ROLE?OBJECT
verb: elect ROLE?OBJECT
verb: eliminate ROLE?OBJECT
verb: embark ROLE!OBJECT
verb: embody ROLE?OBJECT
verb: embrace ROLE?OBJECT
verb: emerge
verb: emphasise ROLE?OBJECT
verb: employ ROLE?OBJECT
verb: empty
verb: enable ROLE?OBJECT
verb: enclose ROLE?OBJECT
verb: encompass ROLE?OBJECT
verb: encounter ROLE?OBJECT
verb: encourage ROLE?OBJECT
verb: end
verb: endorse ROLE?OBJECT
verb: endure ROLE?OBJECT
verb: enforce ROLE?OBJECT
verb: engage ROLE?OBJECT
verb: enhance ROLE?OBJECT
verb: enjoy ROLE?OBJECT
verb: enquire ROLE!OBJECT
verb: ensure ROLE?OBJECT
verb: entail ROLE?OBJECT
verb: enter
verb: entertain
verb: entitle ROLE?OBJECT
verb: envisage ROLE?OBJECT
verb: equal ROLE?OBJECT
verb: equip ROLE?OBJECT
verb: erect ROLE?OBJECT
verb: escape
verb: establish ROLE?OBJECT
verb: estimate ROLE?OBJECT
verb: evaluate ROLE?OBJECT
verb: evoke ROLE?OBJECT
verb: evolve
verb: exaggerate
verb: examine ROLE?OBJECT
verb: exceed ROLE?OBJECT
verb: exchange ROLE?OBJECT
verb: excite ROLE?OBJECT
verb: exclaim
verb: exclude ROLE?OBJECT
verb: excuse ROLE?OBJECT
verb: execute ROLE?OBJECT
verb: exercise
verb: exert ROLE?OBJECT
verb: exhaust ROLE?OBJECT
verb: exhibit ROLE?OBJECT
verb: exist
verb: expand
verb: expect ROLE?OBJECT
verb: expel ROLE?OBJECT
verb: experience ROLE?OBJECT
verb: experiment
verb: explain
verb: explode
verb: exploit ROLE?OBJECT
verb: explore
verb: export ROLE?OBJECT
verb: expose ROLE?OBJECT
verb: express ROLE?OBJECT
verb: extend
verb: extract ROLE?OBJECT
verb: face ROLE?OBJECT
verb: facilitate ROLE?OBJECT
verb: fade
verb: fail
verb: fall ROLE!OBJECT
verb: fan ROLE?OBJECT
verb: fancy ROLE?OBJECT
verb: fascinate
verb: favour ROLE?OBJECT
verb: fear ROLE?OBJECT
verb: feature ROLE?OBJECT
verb: feed ROLE?OBJECT
verb: feel ROLE?OBJECT
verb: fetch ROLE?OBJECT
verb: fight
verb: figure ROLE?OBJECT
verb: file ROLE?OBJECT
verb: fill ROLE?OBJECT
verb: film ROLE?OBJECT
verb: filter ROLE?OBJECT
verb: finance ROLE?OBJECT
verb: find ROLE?OBJECT
verb: finish
verb: fire
verb: fish
verb: fit
verb: fix ROLE?OBJECT
verb: flash ROLE?OBJECT
verb: flee
verb: flick ROLE?OBJECT
verb: fling ROLE?OBJECT
verb: float
verb: flood
verb: flourish ROLE?OBJECT
verb: flow ROLE!OBJECT
verb: flush
verb: fly
verb: focus
verb: fold
verb: follow ROLE?OBJECT
verb: fool ROLE?OBJECT
verb: forbid ROLE?OBJECT
verb: force ROLE?OBJECT
verb: forecast ROLE?OBJECT
verb: forge ROLE?OBJECT
verb: forget
verb: forgive
verb: form ROLE?OBJECT
verb: formulate ROLE?OBJECT
verb: foster ROLE?OBJECT
verb: found ROLE?OBJECT
verb: frame ROLE?OBJECT
verb: free ROLE?OBJECT
verb: freeze
verb: frighten ROLE?OBJECT
verb: frown ROLE!OBJECT
verb: frustrate ROLE?OBJECT
verb: fuck
verb: fulfil ROLE?OBJECT
verb: function
verb: fund ROLE?OBJECT
verb: furnish ROLE?OBJECT
verb: gain ROLE?OBJECT
verb: gasp ROLE!OBJECT
verb: gather ROLE?OBJECT
verb: gaze ROLE!OBJECT
verb: generate ROLE?OBJECT
verb: get ROLE?OBJECT
verb: give ROLE?OBJECT
verb: glance ROLE!OBJECT
verb: glare ROLE!OBJECT
verb: glow ROLE!OBJECT
verb: go ROLE!OBJECT
verb: govern ROLE?OBJECT
verb: grab ROLE?OBJECT
verb: graduate
verb: grant ROLE?OBJECT
verb: grasp ROLE?OBJECT
verb: greet ROLE?OBJECT
verb: grin ROLE!OBJECT
verb: grind ROLE?OBJECT
verb: grip ROLE?OBJECT
verb: groan ROLE!OBJECT
verb: group ROLE?OBJECT
verb: grow
verb: guarantee ROLE?OBJECT
verb: guard ROLE?OBJECT
verb: guess ROLE!OBJECT
verb: guide ROLE?OBJECT
verb: halt
verb: hand ROLE?OBJECT
verb: handicap
verb: handle ROLE?OBJECT
verb: hang
verb: happen
verb: harm ROLE?OBJECT
verb: hate
verb: haul ROLE?OBJECT
verb: haunt
verb: have ROLE?OBJECT
verb: head ROLE?OBJECT
verb: heal
verb: hear
verb: heat
verb: help
verb: hesitate
verb: hide
verb: highlight ROLE?OBJECT
verb: hint
verb: hire ROLE?OBJECT
verb: hit
verb: hold
verb: honour ROLE?OBJECT
verb: hook ROLE?OBJECT
verb: hope
verb: host
verb: house
verb: hover
verb: hug
verb: hunt
verb: hurry
verb: hurt
verb: identify
verb: ignore
verb: illuminate
verb: illustrate
verb: imagine
verb: implement
verb: imply
verb: import
verb: impose
verb: impress
verb: imprison
verb: improve
verb: include
verb: incorporate
verb: increase
verb: incur
verb: indicate
verb: induce
verb: indulge
verb: infect
verb: inflict
verb: influence
verb: inform
verb: inherit
verb: inhibit
verb: initiate
verb: inject
verb: injure
verb: insert
verb: insist
verb: inspect
verb: inspire
verb: instal
verb: install
verb: instruct
verb: insure
verb: integrate
verb: intend
verb: intensify
verb: interest
verb: interfere
verb: interpret
verb: interrupt
verb: intervene
verb: interview
verb: introduce
verb: invade
verb: invent
verb: invest
verb: investigate
verb: invite
verb: invoke
verb: involve
verb: issue
verb: jail
verb: jerk
verb: join
verb: joke
verb: judge
verb: jump
verb: justify
verb: keep
verb: kick
verb: kill
verb: kiss ROLE?OBJECT
verb: kneel
verb: knit
verb: knock
verb: know
verb: label
verb: lack
verb: land
verb: last
verb: laugh
verb: launch
verb: lay
verb: lead
verb: leak
verb: lean
verb: leap
verb: learn
verb: leave
verb: lend
verb: let
verb: level
verb: license
verb: lick
verb: lie
verb: lift
verb: light
verb: like
verb: limit
verb: line
verb: linger
verb: link
verb: list
verb: listen ROLE!OBJECT
verb: listen ROLE?OBJECT to
verb: live
verb: load
verb: locate
verb: lock
verb: lodge
verb: long
verb: look
verb: lose
verb: love
verb: lower
verb: maintain
verb: make
verb: manage
verb: manifest
verb: manipulate
verb: manufacture
verb: map
verb: march
verb: mark
verb: market
verb: marry
verb: master
verb: match
verb: matter
verb: may
verb: mean
verb: measure
verb: meet
verb: melt
verb: mention
verb: merge
verb: mind
verb: minimise
verb: miss
verb: mistake
verb: mix
verb: moan
verb: model
verb: modify
verb: monitor
verb: motivate
verb: mount
verb: move
verb: multiply
verb: murder
verb: murmur
verb: mutter
verb: name
verb: narrow
verb: need
verb: neglect
verb: negotiate
verb: nod
verb: nominate
verb: note
verb: notice
verb: notify
verb: nurse
verb: obey
verb: object
verb: oblige
verb: obscure
verb: observe
verb: obtain
verb: occupy
verb: occur
verb: offend
verb: offer
verb: offset
verb: omit
verb: open
verb: operate
verb: oppose
verb: opt
verb: order
verb: organise
verb: originate
verb: outline
verb: overcome
verb: overlook
verb: overtake
verb: overwhelm
verb: owe
verb: own
verb: pack
verb: package
verb: paint
verb: park
verb: part
verb: participate
verb: pass
verb: pat
verb: pause
verb: pay
verb: peer
verb: penetrate
verb: perceive
verb: perform
verb: permit
verb: persist
verb: persuade
verb: phone
verb: photograph
verb: pick
verb: picture
verb: pile
verb: pin
verb: place
verb: plan
verb: plant
verb: play
verb: plead
verb: please
verb: pledge
verb: plot
verb: plug
verb: plunge
verb: point
verb: poison
verb: polish
verb: pop
verb: portray
verb: pose
verb: position
verb: possess
verb: post
verb: postpone
verb: pour
verb: power
verb: practise
verb: praise
verb: pray
verb: preach
verb: precede
verb: predict
verb: prefer
verb: prepare
verb: prescribe
verb: present
verb: preserve
verb: press
verb: presume
verb: pretend
verb: prevail ROLE!OBJECT
verb: prevent ROLE?OBJECT
verb: price
verb: print
verb: probe
verb: proceed
verb: process
verb: proclaim
verb: produce
verb: profit
verb: program
verb: progress
verb: prohibit
verb: project
verb: promise
verb: promote
verb: prompt
verb: pronounce
verb: prop
verb: propos
verb: propose
verb: prosecute
verb: protect
verb: protest
verb: prove
verb: provide
verb: provoke
verb: publish
verb: pull
verb: pump
verb: punch
verb: punish
verb: purchase
verb: pursue
verb: push
verb: put
verb: puzzle
verb: qualify
verb: question
verb: quit
verb: quote
verb: race
verb: rain
verb: raise
verb: rally
verb: range
verb: rank
verb: rape
verb: rate
verb: reach
verb: react
verb: read
verb: realise
verb: realize
verb: rear
verb: reassure
verb: rebuild
verb: recall
verb: receive
verb: reckon
verb: recognise
verb: recognize
verb: recommend
verb: reconcile
verb: record
verb: recover
verb: recruit
verb: recycle
verb: reduce
verb: refer
verb: reflect
verb: reform
verb: refuse
verb: regain
verb: regard
verb: register
verb: regret
verb: regulate
verb: reinforce
verb: reject
verb: relate
verb: relax
verb: release
verb: relieve
verb: rely
verb: remain
verb: remark
verb: remember
verb: remind
verb: remove
verb: render
verb: renew
verb: repair
verb: repay
verb: repeat
verb: replace
verb: reply
verb: report
verb: represent
verb: reproduce
verb: request
verb: require
verb: rescue
verb: research
verb: resemble
verb: resent
verb: reserve
verb: resign
verb: resist
verb: resolve
verb: respect
verb: respond
verb: rest
verb: restore
verb: restrain
verb: restrict
verb: result
verb: resume
verb: retain
verb: retire
verb: retreat
verb: retrieve
verb: return
verb: reveal
verb: reverse
verb: revert
verb: review
verb: revise
verb: revive
verb: reward
verb: rid
verb: ride
verb: ring
verb: rip
verb: rise
verb: risk
verb: roar
verb: rob
verb: rock
verb: roll
verb: root
verb: round
verb: row
verb: rub
verb: ruin
verb: rule
verb: run
verb: rush
verb: sack
verb: sacrifice
verb: sail
verb: sample
verb: satisfy
verb: save
verb: say
verb: scan
verb: scar
verb: scatter
verb: schedule
verb: score
verb: scramble
verb: scrape
verb: scratch
verb: scream
verb: screen
verb: screw
verb: seal
verb: search
verb: seat
verb: secure
verb: see
verb: seek
verb: seem
verb: seize
verb: select
verb: sell
verb: send
verb: sense
verb: sentence
verb: separate
verb: serve
verb: service
verb: set
verb: settle
verb: shake
verb: shape
verb: share
verb: shatter
verb: shed
verb: shift
verb: shine
verb: ship
verb: shiver
verb: shock
verb: shoot
verb: shop
verb: shout
verb: show
verb: shrink
verb: shrug
verb: shut ROLE?OBJECT
verb: sigh
verb: sign
verb: signal
verb: sing
verb: sink
verb: sip
verb: sit
verb: situate
verb: skill
verb: slam
verb: slap
verb: sleep
verb: slide
verb: slip
verb: slow
verb: slump
verb: smash
verb: smell
verb: smile
verb: smoke
verb: smooth
verb: snap
verb: snatch
verb: sniff
verb: soak
verb: soar
verb: soften
verb: solve
verb: sort
verb: sound
verb: spare
verb: speak
verb: specialise
verb: specify
verb: speed
verb: spell
verb: spend
verb: spill
verb: spin
verb: spit
verb: split
verb: spoil
verb: sponsor
verb: spot
verb: spray
verb: spread
verb: spring
verb: square
verb: squeeze
verb: stab
verb: staff
verb: stag
verb: stagger
verb: stain
verb: stake
verb: stamp
verb: stand
verb: star
verb: start
verb: startle
verb: state
verb: stay
verb: steal
verb: steer
verb: stem
verb: step
verb: stick
verb: stimulate
verb: stir
verb: stop
verb: store
verb: storm
verb: straighten
verb: strain
verb: strengthen
verb: stress
verb: stretch
verb: stride
verb: strike
verb: strip
verb: strive
verb: stroke
verb: stroll
verb: structure
verb: struggle ROLE!OBJECT
verb: study
verb: stuff
verb: stumble
verb: subject
verb: submit
verb: substitute
verb: succeed
verb: suck
verb: sue
verb: suffer
verb: suggest
verb: suit
verb: sum
verb: summarise
verb: summon
verb: supervise
verb: supplement
verb: supply
verb: support
verb: suppose
verb: suppress
verb: surprise
verb: surrender
verb: surround
verb: survey
verb: survive
verb: suspect
verb: suspend
verb: sustain
verb: swallow
verb: swap
verb: sway
verb: swear
verb: sweep
verb: swell
verb: swim
verb: swing
verb: switch
verb: tackle
verb: take
verb: talk
verb: tap
verb: target
verb: taste
verb: tax
verb: teach
verb: tear
verb: tease
verb: telephone
verb: tell
verb: tempt
verb: tend
verb: term
verb: terminate
verb: terrify
verb: test
verb: thank
verb: think
verb: threaten
verb: throw
verb: thrust
verb: tick
verb: tie
verb: tighten
verb: time
verb: tip
verb: tolerate
verb: top
verb: toss
verb: total
verb: touch
verb: tour
verb: trace
verb: track
verb: trade
verb: trail
verb: train
verb: transfer
verb: transform
verb: translate
verb: transmit
verb: transport
verb: trap
verb: travel
verb: tread
verb: treat
verb: tremble
verb: trigger
verb: trip
verb: trouble
verb: trust
verb: try
verb: tuck
verb: tumble
verb: tune
verb: turn
verb: twist
verb: uncover
verb: undergo ROLE?OBJECT
verb: underline ROLE?OBJECT
verb: undermine ROLE?OBJECT
verb: understand
verb: undertake ROLE?OBJECT
verb: unite
verb: update
verb: upgrade
verb: uphold ROLE?OBJECT
verb: upset ROLE?OBJECT
verb: urge
verb: use ROLE?OBJECT
verb: utter ROLE?OBJECT
verb: value ROLE?OBJECT
verb: vanish
verb: vary
verb: venture
verb: view
verb: visit
verb: volunteer
verb: vote
verb: wait
verb: wake
verb: walk
verb: wander
verb: want
verb: warm
verb: warn
verb: wash
verb: waste
verb: watch
verb: wave
verb: weaken
verb: wear
verb: weave
verb: weep
verb: weigh
verb: welcome
verb: wet
verb: whip
verb: whisper
verb: widen
verb: will
verb: win
verb: wind
verb: wipe
verb: wish
verb: withdraw
verb: witness
verb: wonder
verb: work
verb: worry
verb: wound
verb: wrap
verb: write
verb: yell
verb: yield

dontknow: as
dontknow: ever
dontknow: minus
dontknow: not
__END__

=pod

# Local variables:
# compile-command: "scp -q say.pl taxi:/var/www/dh/"
# compile-command: "say.pl"
# End:
