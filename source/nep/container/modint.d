module nep.container.modint;

struct ModInt(ulong modulus) {
  import std.traits : isIntegral, isBoolean;
  import std.exception : enforce;

  private {
    ulong val;
  }

  this(const ulong n) {
    val = n % modulus;
  }

  this(const ModInt n) {
    val = n.value;
  }

  @property {
    ref inout(ulong) value() inout {
      return val;
    }
  }

  T opCast(T)() {
    static if (isIntegral!T) {
      return cast(T)(val);
    } else if (isBoolean!T) {
      return val != 0;
    } else {
      enforce(false, "cannot cast from " ~ this.stringof ~ " to " ~ T.stringof ~ ".");
    }
  }

  ModInt opAssign(const ulong n) {
    val = n % modulus;
    return this;
  }

  ModInt opOpAssign(string op)(ModInt rhs) {
    static if (op == "+") {
      val += rhs.value;
      if (val >= modulus) {
        val -= modulus;
      }
    } else if (op == "-") {
      if (val < rhs.value) {
        val += modulus;
      }
      val -= rhs.value;
    } else if (op == "*") {
      val = val * rhs.value % modulus;
    } else if (op == "/") {
      this *= rhs.inv;
    } else if (op == "^^") {
      ModInt res = 1;
      ModInt t = this;
      while (rhs.value > 0) {
        if (rhs.value % 2 != 0) {
          res *= t;
        }
        t *= t;
        rhs /= 2;
      }
      this = res;
    } else {
      enforce(false, op ~ "= is not implemented.");
    }

    return this;
  }

  ModInt opOpAssign(string op)(ulong rhs) {
    static if (op == "+") {
      val += rhs;
      if (val >= modulus) {
        val -= modulus;
      }
    } else if (op == "-") {
      if (val < rhs) {
        val += modulus;
      }
      val -= rhs;
    } else if (op == "*") {
      val = val * rhs % modulus;
    } else if (op == "/") {
      this *= ModInt(rhs).inv;
    } else if (op == "^^") {
      ModInt res = 1;
      ModInt t = this;
      while (rhs > 0) {
        if (rhs % 2 != 0) {
          res *= t;
        }
        t *= t;
        rhs /= 2;
      }
      this = res;
    } else {
      enforce(false, op ~ "= is not implemented.");
    }

    return this;
  }

  ModInt opUnary(string op)() {
    static if (op == "++") {
      this += 1;
    } else if (op == "--") {
      this -= 1;
    } else {
      enforce(false, op ~ " is not implemented.");
    }
    return this;
  }

  ModInt opBinary(string op)(const ulong rhs) const {
    mixin("return ModInt(this) " ~ op ~ "= rhs;");
  }

  ModInt opBinary(string op)(ref const ModInt rhs) const {
    mixin("return ModInt(this) " ~ op ~ "= rhs;");
  }

  ModInt opBinary(string op)(const ModInt rhs) const {
    mixin("return ModInt(this) " ~ op ~ "= rhs;");
  }

  ModInt opBinaryRight(string op)(const ulong lhs) const {
    mixin("return ModInt(this) " ~ op ~ "= lhs;");
  }

  long opCmp(ref const ModInt rhs) const {
    return cast(long)value - cast(long)rhs.value;
  }

  bool opEquals(const ulong rhs) const {
    return value == ModInt(rhs).value;
  }

  ModInt inv() const {
    ModInt ret = this;
    ret^^=modulus - 2;
    return ret;
  }

  string toString() const {
    import std.format : format;

    return format("%s", val);
  }
}

template isModInt(T) {
  immutable enum isModInt = is(T: ModInt!M, uint M);
}

struct Combination(T) if (isModInt!T) {
  private {
    T[] fact, invFact;

    T[] makeFactTable(T)(size_t n) if (isModInt!T) {
      import std.range : take, recurrence;
      import std.array : array;

      return T(1).recurrence!((a, n) => a[n - 1] * n).take(n).array;
    }

    T[] makeInvFactTable(T)(size_t n) if (isModInt!T) {
      auto fact = makeFactTable!T(n);
      T[] invFact = new T[n];
      foreach (i; 0 .. n) {
        invFact[i] = fact[i].inv;
      }

      return invFact;
    }

  }

  this(size_t size) {
    fact = makeFactTable(size + 1);
    invFact = makeInvFactTable(size + 1);
  }

  // 組み合わせ
  T C(int n, int r) const {
    if (r < 0 || n < r) return 0;

    return fact[n] * invFact[r] * invFact[n - r];
  }

  // 重複組み合わせ
  T H(int n, int r) const {
    if (n < 0 || r < 0) return 0;

    return r == 0 ? 1 : C(n + r - 1, r);
  }

  // 順列
  T P(int n, int r) const {
    if (r < 0 || n < r) return 0;

    return fact[n] * invFact[n - r];
  }
}

// unittest {{{

@system unittest {
  import std.algorithm : equal, map;
  import std.stdio : writeln;

  immutable MOD = 13;
  ModInt!MOD[] ar;
  foreach (i; 1 .. 13) {
    ar ~= ModInt!MOD(i);
  }

  assert(equal(ar.map!"a.inv", [1, 7, 9, 10, 8, 11, 2, 5, 3, 4, 6, 12]));
}

// }}}
