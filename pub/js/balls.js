#!/usr/bin/node

/* eslint-disable no-console */

// Given "m" balls that all weigh the same except one that is heavier or
// lighter than the rest, what is the minimum number of weighings it takes
// to find which ball is different and whether it is heavier or lighter?

// Supplementary questions:

// If m is even, can weighing m/2 vs m/2 ever be on a shortest sequence?

// Each ball is either standard, heavy or light.
// At any time, each ball is in one of six groups:

const allGroups = [ // HL
  'strange', // ?? One heavy or one light
  'brother', // 0? None heavy
  'dark', // ?0 None light
  'heavy', // 10 One heavy
  'light', // 01 One light
  'standard', // 00 None heavy, none light
];

function assert(ok, ...args) {
  if (ok) return;
  // console.error('assertion failed:', args.join(' ')); process.exit(1);
  throw new Error(`assertion failed: ${args.join(' ')}`);
}

// function todo() { throw Error('todo'); }

function fromTo(from, to) {
  const result = [];
  for (let i = from; i <= to; i++) result.push(i);

  return result;
}

// Base class for State and Selection

class SS {
  constructor(s) {
    Object.keys(s).forEach((k) => { this[k] = s[k]; });
  }

  groups() { return Object.keys(this); }

  toString() {
    const strings = this.groups().reduce((ss, g) => {
      const n = this[g];
      if (n) ss.push(`${n} ${g}`);
      return ss;
    }, []);
    const s = strings.join(', ');

    return `<${s}>`;
  }
}

// A Selection is a State with different methods

class Selection extends SS {
  // Return a new Selection formed by adding "sel" and this one

  add(sel) {
    const copy = new Selection(this);
    const gs = sel.groups();
    const result = gs.reduce((res, g) => ({ ...res, [g]: res[g] + sel[g] }), copy);

    return result;
  }
}

// A State is an object { group: numBallsInGroup, ... }

class State extends SS {
  // Return all weighings based on state

  weighings() {
    const weighMax = Math.floor(this.total() / 2);
    const ws = fromTo(1, weighMax).map(n => this.weighNumBalls(n));

    return ws;
  }

  // Return all different weighings with "n" balls in each pan, selected from "state"

  weighNumBalls(n) {
    assert(n, 'No balls');
    console.log(`All weighings of ${n} per pan from ${this.toString()}`);
    const results = [];
    const leftSelections = this.selections(n);
    console.log(' Lefts', leftSelections.toString());
    leftSelections.forEach((left) => {
      const remain = this.subtract(left);
      console.log('  Left', left.toString(), 'leaves', remain.toString());
      const rightSelections = remain.selections(n);
      console.log('   Rights', rightSelections.toString());
      rightSelections.forEach((right) => {
        const rest = remain.subtract(right);
        console.log('   Right', right.toString(), 'Rest', rest.toString());
        const w = [left, right, rest];
        console.log('    ', w.toString());
        results.push(w);
      });
    });
    return results;
  }

  // Return all possible selections of "nTotal" balls from state

  selections(numTotal) {
    assert(numTotal, 'Selecting from zero balls');
    const stateGroups = this.groups();
    const results = stateGroups.map(g => this.selectionsWithGroup(numTotal, g));
    console.log(' Selected', numTotal, `from ${this.toString()} =>`, results);

    return results;
  }

  // Return all selections of "nTotal" balls from state starting with group g

  selectionsWithGroup(numTotal, g) {
    const maxFromGroup = Math.min(this[g], numTotal);
    assert(maxFromGroup, `Nothing from ${g}`);
    const numsFromGroup = fromTo(1, maxFromGroup);
    console.log(' Select', numsFromGroup, 'of', numTotal, `from ${this} starting with`, g);
    const sels = numsFromGroup.map(n => this.selectionsWithNumOfGroup(numTotal - n, g, n));

    return sels;
  }

  // Return all ways of extending a selection of n of g with numLeft to select from

  selectionsWithNumOfGroup(numLeft, g, n) {
    const sel = new Selection({ [g]: n });
    const remain = this.removeGroup(g);
    console.log(` Select ${sel.toString()} of ${this.toString()} leaving ${numLeft} in ${remain}`);
    if (!numLeft) return [sel];
    const moreSels = remain.selections(numLeft);
    console.log(` Select ${sel.toString()} of ${this.toString()} leaving ${remain.toString()} giving`, moreSels);
    const result = moreSels.map(more => sel.add(more));

    return result;
  }

  // Return a copy of state without g

  removeGroup(g) {
    assert(this[g], `Can't remove ${g} from ${this}`);
    const result = new State(this);
    delete result[g];

    return result;
  }

  // Return state after removing selection

  subtract(selection) {
    const result = this.groups().reduce((res, g) => {
      const nSel = selection[g] || 0;
      const nState = this[g] || 0;
      const nRemain = nState - nSel;
      assert(nRemain >= 0, "Can't subtract", nSel, 'from', nState);
      if (nRemain) res[g] = nRemain;
      return res;
    }, new State({}));

    return result;
  }

  isEmpty() { return Object.keys(this).length === 0; }

  total() { return allGroups.reduce((tot, g) => tot + (this[g] || 0), 0); }

  isSolved() { return ['heavy', 'light'].some(g => this[g] === 1); }
}

// class States {
//   static toString(states) {
//     // console.log('States toString', states[0].groups());
//     const ss = states.map(s => s.toString());
//     const s = ss.join(', ');

//     return `[${s}]`;
//   }
// }

// A sequence, [state, weigh, state, ..., weigh, state],
// starts with all balls in the strange group and ends
// with exactly one ball in either heavy or light group.

class Sequence extends Array {
  // Exit if the sequence's final state is a solution, else
  // extend it with all possible weighings based on that state.

  extend() {
    const state = this.last();
    // console.log('Extend', this.toString(), 'ending with', state.toString());
    if (state.isSolved()) return;
    const ws = state.weighings();
    console.log('Extend', state.toString(), '->', ws.toString());
    ws.forEach((w) => {
      const nextStates = state.weigh(w);
      nextStates.forEach((nextState) => {
        this.extend([w, nextState]);
      });
    });
  }

  last() { return this[this.length - 1]; }

  toString() {
    const ss = this.map(sw => sw.toString());
    const s = ss.join(', ');

    return `{{${s}}}`;
  }
}

/* eslint-disable no-extend-native */

Array.prototype.flatten = function flatten() {
  return this.reduce((res, a) => res.concat(a), []);
};

/* eslint-enable no-extend-native */

// Try all different sequences of weighings to find the shortest.

function puzzle(ballsTotal) {
  const state = new State({ strange: ballsTotal });
  const sequence = new Sequence(state);
  sequence.extend();
}

// A weighing is the states [left, right, unweighed].  E.g.
// left: 3 strange; right: 1 standard, 2 dark; unweighed: 2 strange

// Return all possible result states after weighing left vs right with unweighed

// function weigh(left, right, unweighed) {
//   console.log(showState(left), 'vs', showState(right), 'leaving', showState(unweighed));

//   // A weighing results in the pans being up-down, down-up or level.

//   [['u', 'd'], ['d', 'u'], ['=', '=']].forEach(([l, r]) => {
//     console.log('Left', l, 'Right', r);
//     const leftResult = pan(left, l, right);
//     const rightResult = pan(right, r, left);
//     const unResult = notWeighed(unweighed, l === '=');
//   });
// }

// Weighings change balls' groups:

// Balanced  -> standard
// Up vs standards           -> light
// Down vs standards         -> heavy
// Up vs not all standards   -> brother
// Down vs not all standards -> dark

// function pan(selection, result, otherPan) {
//   const othersAllStandard = allStandard(otherPan);
//   console.log('Pan', selection, result, 'vs', otherPan);
// }

// function allStandard(selection) {
// }

// Not part of an unbalanced weighing -> standard

// function unWeighed(selection, balanced) {
// }

// function showWeighings(ws) { return ws.map(showWeighing).join(', '); }

// function showWeighing(w) {
//   const [left, right, rest] = w;

//   return `Weigh ${showState(left)} vs ${showState(right)} leaving ${showState(rest)}`;
// }

puzzle(4);
