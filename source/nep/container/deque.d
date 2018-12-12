module nep.container.deque;

struct Deque(T, bool mayNull = true) {
  import std.traits : isImplicitlyConvertible;
  import std.range : ElementType, isInputRange;
  import std.exception;

  alias Payload = DequePayload!T;
  alias opDollar = length;
  alias opOpAssign(string op : "~") = insertBack;

  // DequePayload {{{
  private struct DequePayload(T, size_t pageSize = 4) {
    import std.traits : isMutable;
    import core.exception : RangeError;

    this(this) @disable;

    void opAssign(DequePayload rhs) @disable;

    private {
      T[][] _data;
      size_t top, len, cap;
    }

    alias opDollar = length;
    alias opOpAssign(string op : "~") = insertBack;

    @property {
      bool empty() const {
        return len == 0;
      }

      size_t length() const {
        return len;
      }

      ref inout(T) front() inout {
        return this[0];
      }

      ref inout(T) back() inout {
        return this[$ - 1];
      }
    }

    ref inout(T) opIndex(size_t idx) inout {
      if (len <= idx) {
        throw new RangeError();
      }

      if (top + idx < cap) {
        return _data[(top + idx) / pageSize][(top + idx) % pageSize];
      }

      return _data[(top + idx - cap) / pageSize][(top + idx - cap) % pageSize];
    }

    void reserve(size_t newCap) {
      size_t nextCap = 1;
      while (nextCap < newCap)
        nextCap <<= 1;

      import std.math : abs;

      if (nextCap <= cap)
        return;

      size_t newArrSize = nextCap / pageSize - cast(size_t)(nextCap % pageSize == 0) + 1;
      size_t nowArrSize = cap / pageSize - cast(size_t)(cap % pageSize == 0) + 1;
      if (newArrSize <= nowArrSize)
        return;

      foreach (i; 0 .. newArrSize - nowArrSize) {
        _data ~= new T[pageSize];
      }

      top = 0;
      cap = nextCap;
    }

    void insertBack(E)(E value) if (isImplicitlyConvertible!(E, T)) {
      import std.algorithm : max;

      if (len == cap) {
        reserve(max(cap * 2 * pageSize, 4 * pageSize));
      }

      ++len;
      this[$ - 1] = value;
    }

    void popBack() {
      assert(!empty, "nep.container.Deque.popBack: Deque is empty.");

      --len;
    }

    void clear() {
      top = 0;
      len = 0;
    }

    void insertFront(E)(E value) if (isImplicitlyConvertible!(E, T)) {
      import std.algorithm : max;

      if (len == cap) {
        reserve(max(cap * 2 * pageSize, 4 * pageSize));
      }

      if (top == 0) {
        top += cap;
      }

      --top;
      ++len;
      this[0] = value;
    }

    void popFront() {
      assert(!empty, "nep.container.Deque.popFront: Deque is empty.");

      ++top;
      --len;
      if (top == cap) {
        top = 0;
      }
    }

    string toString() const {
      import std.format : format;

      string ret = "[";
      foreach (i; 0 .. len) {
        ret ~= format("%s%s", this[i], i == len - 1 ? "]" : ", ");
      }

      return ret;
    }
  }
  // }}}

  // RangeT {{{
  private struct RangeT(A) {
    import std.traits : CopyTypeQualifiers, isMutable;

    alias E = CopyTypeQualifiers!(A, T);

    alias opDollar = length;

    private {
      A* _outer;
      size_t _l, _r;

      this(A* ptr, size_t l, size_t r) {
        _outer = ptr;
        _l = l;
        _r = r;
      }
    }

    @property {
      bool empty() const {
        return _l >= _r;
      }

      size_t length() const {
        return _r - _l;
      }

      RangeT save() {
        return this;
      }

      ref inout(E) front() inout {
        return this[0];
      }

      ref inout(E) back() inout {
        return this[$ - 1];
      }
    }

    void popFront() {
      assert(!empty,
          "nep.container.deque.RangeT.popFront: Attempting to access the front of an empty Deque");

      ++_l;
    }

    void popBack() {
      assert(!empty,
          "nep.container.deque.RangeT.popBack: Attempting to access the back of an empty Deque");

      --_r;
    }

    ref inout(E) opIndex(size_t idx) inout {
      assert(_l + idx < _r);

      return (*_outer)[_l + idx];
    }

    RangeT opSlice() {
      return RangeT(_outer, _l, _r);
    }

    RangeT opSlice(size_t i, size_t j) {
      assert(i <= j && _l + i <= _r);

      return RangeT(_outer, _l + i, _l + j);
    }

    static if (isMutable!A) {
      void opSliceAssign(E value) {
        assert(_r <= _outer.length);

        foreach (idx; _l .. _r) {
          (*_outer)[idx] = value;
        }
      }

      void opSliceAssign(E value, size_t i, size_t j) {
        assert(_l + j <= _r);

        foreach (idx; _l + i .. _l + j) {
          (*_outer)[idx] = value;
        }
      }

      void opSliceUnary(string op)() if (op == "++" || op == "--") {
        assert(_r <= _outer.length);

        foreach (idx; _l .. _r) {
          mixin(op ~ "(*_outer)[idx];");
        }
      }

      void opSliceUnary(string op)(size_t i, size_t j) if (op == "++" || op == "--") {
        assert(_l + j <= _r);

        foreach (idx; _l + i .. _l + j) {
          mixin(op ~ "(*_outer)[idx];");
        }
      }

      void opSliceOpAssign(string op)(E value) {
        assert(_r <= _outer.length);

        foreach (idx; _l .. _r) {
          mixin("(*_outer)[idx] " ~ op ~ "= value;");
        }
      }

      void opSliceOpAssign(string op)(E value, size_t i, size_t j) {
        assert(_l + j <= _r);

        foreach (idx; _l + i .. _l + j) {
          mixin("(*_outer)[idx] " ~ op ~ "= value;");
        }
      }
    }
  }
  // }}}

  private {
    Payload* p;
  }

  this(A)(A[] args...) if (isImplicitlyConvertible!(A, T)) {
    p = new Payload();

    foreach (e; args) {
      this ~= e;
    }
  }

  this(Range)(Range r)
      if (isInputRange!Range && isImplicitlyConvertible!(ElementType!Range,
        T) && !is(Range == T[])) {
    insertBack(r);
  }

  @property {
    bool empty() const {
      return !(!mayNull || p) || p.empty;
    }

    size_t length() const {
      return !mayNull || p ? p.length : 0;
    }

    ref inout(T) front() inout {
      return p.front;
    }

    ref inout(T) back() inout {
      return p.back;
    }
  }

  ref inout(T) opIndex(size_t idx) inout {
    assert(!empty, "nep.container.deque.opIndex: Deque is empty.");

    return (*p)[idx];
  }

  alias Range = RangeT!(DequePayload!T);
  alias ConstRange = RangeT!(const DequePayload!T);
  alias ImmutableRange = RangeT!(immutable DequePayload!T);

  Range opSlice() {
    return typeof(return)(p, 0, length);
  }

  ConstRange opSlice() const {
    return typeof(return)(p, 0, length);
  }

  ImmutableRange opSlice() immutable {
    return typeof(return)(p, 0, length);
  }

  Range opSlice(size_t i, size_t j) {
    return typeof(return)(p, i, j);
  }

  ConstRange opSlice(size_t i, size_t j) const {
    return typeof(return)(p, i, j);
  }

  ImmutableRange opSlice(size_t i, size_t j) immutable {
    return typeof(return)(p, i, j);
  }

  void opSliceAssign(T value) {
    opSlice()[] = value;
  }

  void opSliceAssign(T value, size_t i, size_t j) {
    opSlice()[i .. j] = value;
  }

  void opSliceUnary(string op)() if (op == "++" || op == "--") {
    mixin(op ~ "opSlice()[0 .. $];");
  }

  void opSliceUnary(string op)(size_t i, size_t j) if (op == "++" || op == "--") {
    mixin(op ~ "opSlice()[i .. j];");
  }

  void opSliceOpAssign(string op)(T value) {
    mixin("opSlice()[0 .. $] " ~ op ~ "= value;");
  }

  void opSliceOpAssign(string op)(T value, size_t i, size_t j) {
    mixin("opSlice()[i .. j] " ~ op ~ "= value;");
  }

  void insertBack(T value) {
    if (mayNull && !p) {
      p = new Payload();
    }

    p.insertBack(value);
  }

  void insertBack(Stuff)(Stuff stuff)
      if (isImplicitlyConvertible!(Stuff, T) || isInputRange!Stuff
        && isImplicitlyConvertible!(ElementType!Stuff, T)) {
    foreach (e; stuff) {
      insertBack(e);
    }
  }

  void opOpAssign(string op, Stuff)(Stuff stuff) if (op == "~") {
    static if (is(typeof(stuff[]))) {
      insertBack(stuff[]);
    } else {
      insertBack(stuff);
    }
  }

  void removeBack() {
    assert(!empty, "nep.container.deque.popFront: Deque is empty.");

    p.popBack();
  }

  void insertFront(T value) {
    if (mayNull && !p) {
      p = new Payload();
    }

    p.insertFront(value);
  }

  void removeFront() {
    assert(!mayNull || p, "nep.container.deque.popFront: Deque is empty.");

    p.popFront();
  }

  void clear() {
    if (p) {
      p.clear();
    }
  }

  string toString() const {
    return !empty ? p.toString() : "[]";
  }
}

// unittest {{{
@system unittest {
  auto dq = Deque!int();

  assert(dq.empty);
  dq.insertBack(1);
  dq.insertFront(2);
  dq.insertBack(3);
  dq.insertFront(4);
  dq.insertBack(5);

  import std.algorithm : equal;

  assert(equal(dq[], [4, 2, 1, 3, 5]));
  dq.removeBack();
  assert(equal(dq[], [4, 2, 1, 3]));
  dq.insertBack(6);
  assert(equal(dq[], [4, 2, 1, 3, 6]));
  dq.removeFront();
  assert(equal(dq[], [2, 1, 3, 6]));
  dq.insertFront(7);
  assert(equal(dq[], [7, 2, 1, 3, 6]));

  assert(equal(dq[0 .. 2], [7, 2]));
  assert(equal(dq[2 .. $], [1, 3, 6]));
}

@system unittest {
  import std.algorithm : equal;

  auto dq = Deque!int(1, 2, 3, 4, 5);

  ++dq[0 .. $];
  assert(equal(dq[], [2, 3, 4, 5, 6]));
  --dq[0 .. 3];
  assert(equal(dq[], [1, 2, 3, 5, 6]));
  dq[] *= 2;
  assert(equal(dq[], [2, 4, 6, 10, 12]));
  dq[2 .. $] /= 2;
  assert(equal(dq[], [2, 4, 3, 5, 6]));

  dq ~= 8;

  dq[0 .. $] = 0;

  assert(equal(dq[], [0, 0, 0, 0, 0, 0]));
}

@system unittest {
  import std.algorithm : equal;

  struct T {
    this(int _x) {
      x = _x;
    }

    int x;
  }

  auto dq = Deque!T(T(1), T(2));
  assert(equal(dq[], [T(1), T(2)]));
}

@system unittest {
  import std.algorithm : equal;
  import std.range : iota;

  auto dq = Deque!int(iota(0, 10));
  assert(equal(dq[], iota(0, 10)));
}

@system unittest {
  import std.algorithm : equal;
  import std.range : iota;

  auto dq = Deque!int();

  dq ~= iota(0, 100);
  assert(equal(dq[], iota(0, 100)));
}
// }}}
