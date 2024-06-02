#!/usr/bin/node

// Ball weighing puzzle

// Denis Howe 2019-06-22 - 2019-08-03

// Given "m" balls that all weigh the same except one that is heavier
// or lighter than the rest, how many weighings does it take to find
// which ball is different and whether it is heavier or lighter?

// If m is even, can weighing m/2 v m/2 ever be on a shortest sequence?

/* eslint-disable no-console */

// Each ball is either standard, heavy or light.

function assert(ok, ...args) {
  if (!ok) throw new Error(`assertion failed: ${args.join(' ')}`);
}

/* eslint-disable-next-line no-unused-vars */
function todo() { throw Error('todo'); }

const opposites = { up: 'down', down: 'up', level: 'level' };
const moves = Object.keys(opposites);

// ================================================================================ //

// At any time, each ball is in one of six groups:

const allGroups = [
  'std', // None heavy, none light     - best
  'heavy', // One heavy
  'light', // One light
  'bro', // None heavy
  'dark', // None light
  'strange', // One heavy or one light - worst
];

// Map group to a "rank" that is lower for more interesting groups

const groupRank = []; allGroups.forEach((g, i) => groupRank[g] = i);

// Return < 0 if group A is better than group B

function compareGroups(a, b) { return groupRank[a] - groupRank[b]; }

// Return the better of old and new groups

function betterGroup(oldG, newG) {
  return compareGroups(newG, oldG) < 0 ? newG : oldG;
}

function sortGroups(gs) { return gs.sort(compareGroups); }

// ================================================================================ //

// A Result has a weighing, a left pan movement and a new group for each pan

class Result {
  constructor({ weighing, leftMove, leftGroup, rightGroup, unweighedGroup }) {
    this.weighing = weighing;
    this.leftMove = leftMove;
    this.leftGroup = leftGroup;
    this.rightGroup = rightGroup;
    this.unweighedGroup = unweighedGroup;
  }

  toString() {
    const { weighing, leftMove, leftGroup, rightGroup, unweighedGroup } = this;
    const { left, right, unweighed } = weighing;
    const rightMove = opposites[leftMove];
    const sym = { up: '↑', down: '↓', level: '=' };
    const lSym = sym[leftMove];
    const rSym = sym[rightMove];

    return `${left}${lSym}:${leftGroup} ${right}${rSym}:${rightGroup} ${unweighed}:${unweighedGroup}`;
  }
}

// ================================================================================ //

class List extends Array {
  // Pass a single integer to super else concatenate all the argument arrays

  constructor(...args) {
    if (args.length === 1) {
      const length = args[0];
      if (typeof length === 'number') {
        super(length);
        return;
      }
    }
    super(); // Start empty
    args.forEach(arr => [].push.apply(this, arr));
  }

  static fromTo(from, to) {
    const seq = new List();
    for (let i = from; i <= to; i++) seq.push(i);

    return seq;
  }

  // Given [[a, b], [c, ,d]], return [a, b, c, d]

  flatten() {
    return this.reduce((res, a) => res.concat(a), new List());
  }

  // Given [a, b, c], return [b, c]

  tail() { return this.slice(1); }

  // Given [a, b, c], return [[a, b, c], [b, c], [c]]

  tails() {
    return new List(!this.length ? [] : [this].concat(this.tail().tails()));
  }

  toString() {
    const ss = this.map(s => s.toString());
    const s = ss.join(', ');

    return `[${s}]`;
  }
}

// ================================================================================ //

// A State is an object { group: numBallsInGroup, ... }

// A selection is a State that doesn't necessarily include all balls

class State {
  constructor(s) {
    Object.keys(s).forEach((k) => { this[k] = s[k]; });
  }

  // Return all weighings based on state

  weighings() {
    const weighMax = Math.floor(this.total() / 2);

    return List.fromTo(1, weighMax)
      .map(n => this.weighNumBalls(n))
      .flatten();
  }

  // Return all different weighings with "n" balls in each pan, selected from "state"

  weighNumBalls(n) {
    console.log(`\nAll weighings of ${n} per pan from ${this}`);
    const leftSelections = this.selections(n);
    console.log(` Lefts ${leftSelections}`);
    const wss = leftSelections.map((left) => {
      const remain = this.removeSelection(left);
      console.log(`  Left ${left} from ${this} leaves ${remain}`);
      const rightSelections = remain.selections(n);
      console.log(`   Rights ${rightSelections}`);
      return rightSelections.map((right) => {
        const rest = remain.removeSelection(right);
        /* eslint-disable-next-line no-use-before-define */
        const w = new Weighing(left, right, rest);
        const p = w.pointless();
        console.log(`    ${w}${p ? ' is pointless' : ''}`);
        return !p && w;
      });
    });
    const ws = wss.flatten().filter(w => w);
    // console.log(`All weighings ${ws}`);

    return ws;
  }

  // Return all possible selections of "numWant" balls from state

  selections(numWant) {
    // console.log(` Select ${numWant} from ${this}`);
    assert(numWant > 0, `Want ${numWant} balls`);
    const stateGroups = this.groups();
    const sels = stateGroups
      .tails()
      .map(gs => this.selectionsWithGroups(numWant, gs))
      .flatten();
    console.log(`  Selected ${numWant} from ${this} => ${sels}`);

    return sels;
  }

  // Return all selections of "numWant" balls from group gs of state

  selectionsWithGroups(numWant, gs) {
    const g = gs[0];
    const otherGroups = gs.tail();
    const otherBalls = this.total(otherGroups);
    const minThisGroup = Math.max(numWant - otherBalls, 1);
    const maxThisGroup = Math.min(this[g], numWant);
    const numsFromGroup = List.fromTo(minThisGroup, maxThisGroup);
    const sels = numsFromGroup
      .map(n => this.selectionsWithNumOfGroup(n, g, numWant - n))
      .flatten();
    // console.log(`  Selected ${numWant} from ${this} starting with ${g} => ${sels}`);

    return sels;
  }

  // Return all ways of extending a selection of n of g by selecting numWant more balls

  selectionsWithNumOfGroup(n, g, numWant) {
    assert(n > 0, `Selected ${n} ${g}`);
    const sel = new State({ [g]: n });
    const remain = this.removeGroup(g);
    const sels = numWant ? remain.selections(numWant).map(more => sel.add(more)) : [sel];
    console.log(` Selected ${sel} from ${this} => ${sels}`);

    return sels;
  }

  // Return state's groups, best first

  groups() { return new List(sortGroups(Object.keys(this))); }

  bestGroup() { return this.groups()[0]; }

  worstGroup() { return this.groups().reverse()[0]; }

  // Return a copy of this selection with its balls moved
  // to newGoup if that's better than their current group

  update(newGroup) {
    const sel = new State({});
    this.groups().forEach((g) => {
      const bg = betterGroup(g, newGroup);
      sel[bg] = (sel[bg] || 0) + this[g];
    });
    return sel;
  }

  // Return a new Selection formed by adding "sel" and this one

  add(sel) {
    const copy = new State(this);
    copy.addToState(sel);

    return copy;
  }

  // Add selection "sel" to this state, modifying the subject state

  addToState(sel) { sel.groups().forEach((g) => { this[g] = (this[g] || 0) + sel[g]; }); }

  // Return a copy of state without g

  removeGroup(g) {
    assert(this[g], `Can't remove ${g} from ${this}`);
    const newState = new State(this);
    delete newState[g];

    return newState;
  }

  // Return a copy of state after removing selection.  Only set non-empty groups.

  removeSelection(selection) {
    const newState = new State({});
    this.groups().forEach((g) => {
      const n = this[g] - (selection[g] || 0);
      if (n) newState[g] = n;
    });
    return newState;
  }

  // Return true if this selection has only a 'standard' group

  allStandard() {
    return this.std && !this.groups().find(g => g !== 'std');
  }

  // Return the total number of balls in the state, optionally limited to GROUPS

  total(gs = this.groups()) { return gs.reduce((tot, g) => tot + (this[g] || 0), 0); }

  // Return true if the state is a solution - exactly one ball in heavy or light

  isSolved() { return ['heavy', 'light'].some(g => this[g] === 1); }

  toString() {
    const strings = this.groups().map(g => `${this[g]} ${g}`);
    const s = strings.join(', ');
    const solved = this.isSolved() ? '***' : '';

    return `<${s}${solved}>`;
  }
}

// ================================================================================ //

// A Weighing is a selection for each pan: left, right, unweighed

class Weighing {
  constructor(leftSelection, rightSelection, unweighed) {
    this.left = leftSelection;
    this.right = rightSelection;
    this.unweighed = unweighed;
  }

  // Some weighings are pointless

  pointless() { return this.bothAllStandard() || this.redundant(); }

  // All std vs all std is bound to balance

  bothAllStandard() { return this.left.allStandard() && this.right.allStandard(); }

  // To reduce duplication, best right group should be no better than the worst left group

  redundant() { return compareGroups(this.right.bestGroup(), this.left.worstGroup()) < 0; }

  // Given a left pan movement, return next states for each pan

  weigh(leftMove) {
    const rightMove = opposites[leftMove];
    const leftGroup = Weighing.panNewGroup(leftMove, this.right);
    const rightGroup = Weighing.panNewGroup(rightMove, this.left);
    // Not level => unweighed = standard
    const unweighedGroup = leftMove === 'level' ? undefined : 'std';

    return new Result({ weighing: this, leftMove, leftGroup, rightGroup, unweighedGroup });
  }

  // Return the new group for the balls in this pan depending on how it
  // moved and whether the balls in the other pan were all standard or not

  static panNewGroup(move, otherPan) {
    if (move === 'level') return 'std'; // Level => standard

    const allStd = otherPan.allStandard();
    const up = move === 'up';

    // Against all standard: up -> light, down -> heavy
    // Against some non-standard: up -> brother, down -> dark

    return allStd ? (up ? 'light' : 'heavy') : (up ? 'bro' : 'dark');
  }

  // Return a new State created by updating the states
  // of my pan's selections with the given result

  newState({ leftGroup, rightGroup, unweighedGroup }) {
    const { left, right, unweighed } = this;
    const state = new State({});
    state.addToState(left.update(leftGroup));
    state.addToState(right.update(rightGroup));
    state.addToState(unweighed.update(unweighedGroup));

    return state;
  }

  toString() {
    const { left, right, unweighed } = this;

    return `${left} v ${right} & ${unweighed}`;
  }
}

// ================================================================================ //

// A Sequence, [state, result, state, ..., result, state],
// starts with all balls in the strange group and ends with a solution.

class Sequence extends List {
  // If the sequence's final state is a solution then return,
  // else extend the sequence with all possible weighings based
  // on that state, and, for each weighing, each possible result.

  extend() {
    const state = this.last();
    if (state.isSolved()) return;
    state.weighings().forEach((weighing) => {
      moves.forEach((leftMove) => {
        const result = weighing.weigh(leftMove);
				todo(); // move may be impossible, e.g. all bro down, all dark up
        const newState = weighing.newState(result);
        const newSeq = new Sequence(this);
        newSeq.push(result, newState);
        // console.log(`Extend ${this} by ${result}`);
        console.log(`\n${newSeq}`);
        newSeq.extend();
      });
    });
  }

  last() { return this[this.length - 1]; }

  toString() {
    const ss = this.map(sw => sw.toString());
    const s = ss.join('\n  ');

    return `{{${s}}}`;
  }

  // List all different sequences of weighings

  static puzzle(ballsTotal) {
    const state = new State({ strange: ballsTotal });
    const sequence = new Sequence([state]);
    sequence.extend();
  }
}

Sequence.puzzle(4);
