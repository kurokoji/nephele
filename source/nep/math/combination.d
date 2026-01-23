module nep.math.combination;

import nep.container.modint : isModInt;

struct Combination(T) if (isModInt!T) {
  private {
    T[] fact, invFact;

    T[] makeFactTable(size_t n) {
      import std.range : take, recurrence;
      import std.array : array;

      return T(1).recurrence!((a, n) => a[n - 1] * n).take(n).array;
    }

    T[] makeInvFactTable(size_t n) {
      auto fact = makeFactTable(n);
      T[] retInvFact = new T[n];
      foreach (i; 0 .. n) {
        retInvFact[i] = fact[i].inv;
      }

      return retInvFact;
    }
  }

  this(size_t size) {
    fact = makeFactTable(size + 1);
    invFact = makeInvFactTable(size + 1);
  }

  // Combination
  T C(int n, int r) const {
    if (r < 0 || n < r)
      return T(0);

    return fact[n] * invFact[r] * invFact[n - r];
  }

  // Homogeneous product (combination with repetition)
  T H(int n, int r) const {
    if (n < 0 || r < 0)
      return T(0);

    return r == 0 ? T(1) : C(n + r - 1, r);
  }

  // Permutation
  T P(int n, int r) const {
    if (r < 0 || n < r)
      return T(0);

    return fact[n] * invFact[n - r];
  }
}

// unittest {{{

@system unittest {
  import nep.container.modint : ModInt;

  immutable MOD = 13;
  alias Mint = ModInt!MOD;
  auto comb = Combination!Mint(10);

  assert(comb.C(5, 2) == 10);
  assert(comb.P(5, 2) == 7);
  assert(comb.H(3, 2) == 6);
  assert(comb.C(3, 5) == 0);
  assert(comb.H(-1, 2) == 0);
}

// }}}
