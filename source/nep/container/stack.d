module nep.container.stack;

struct Stack(T, bool mayNull = true) {
  import std.traits : isImplicitlyConvertible;
  import std.range : ElementType, isInputRange;

  alias Payload = StackPayload!T;
  alias opDollar = length;
  alias opOpAssign(string op : "~") = push;

  // StackPayload {{{
  private struct StackPayload(T, size_t minCapacity = 5) if (minCapacity >= 0) {
    private {
      T* _data;
      size_t _capacity, _length;
    }

    alias opDollar = length;
    alias opOpAssign(string op = "~") = insertBack;

    this(this) @disable;
    void opAssign(StackPayload rhs) @disable;

    ~this() {
      import core.memory : GC;

      if (_data != null) {
        GC.free(_data);
      }
    }

    @property {
      size_t length() const {
        return _length;
      }

      size_t capacity() const {
        return _capacity;
      }

      bool empty() const {
        return _length == 0;
      }

      ref inout(T) front() inout {
        assert(!empty, "nep.container.StackPayload.front: Stack is empty.");

        return this[0];
      }

      ref inout(T) back() inout {
        assert(!empty, "nep.container.StackPayload.back: Stack is empty.");
        return this[$ - 1];
      }
    }

    ref inout(T) opIndex(size_t idx) inout {
      import core.exception : RangeError;

      if (_length <= idx) {
        throw new RangeError();
      }

      return _data[idx];
    }

    void reserve(size_t newCapacity) {
      import core.memory : GC;
      import core.stdc.string : memcpy;

      if (_capacity >= newCapacity)
        return;

      T* newData = cast(T*)GC.malloc(T.sizeof * newCapacity);
      if (_length != 0)
        memcpy(newData, _data, _length * T.sizeof);
      _capacity = newCapacity;

      T* oldData = _data;
      _data = newData;
      GC.free(oldData);
    }

    void free() {
      import core.memory : GC;

      GC.free(_data);
      _length = 0;
      _capacity = 0;
    }

    void clear() {
      _length = 0;
    }

    void insertBack(E)(E value) if (isImplicitlyConvertible!(E, T)) {
      if (_length == _capacity) {
        if (_capacity < minCapacity) {
          reserve(minCapacity);
        } else {
          reserve(1 + _capacity * 3 / 2);
        }
      }
      _data[_length++] = value;
    }

    void popBack() {
      assert(!empty(), "nep.container.StackPayload.popBack: Stack is empty.");

      --_length;
    }

    string toString() const {
      import std.format : format;

      string ret = "[";
      foreach (i; 0 .. _length) {
        ret ~= format("%s%s", this[i], i == _length - 1 ? "]" : ", ");
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

      RangeT!A save() {
        return this;
      }
    }

    void popFront() {
      assert(!empty,
          "nep.container.stack.RangeT.popFront: Attempting to access the front of an empty Stack.");

      ++_l;
    }

    void popBack() {
      assert(!empty,
          "nep.container.stack.RangeT.popBack: Attempting to access the back of an empty Stack.");

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
    push(r);
  }

  @property {
    bool empty() const {
      return !(!mayNull || p) || p.empty;
    }

    size_t length() const {
      return !mayNull || p ? p.length : 0;
    }

    ref inout(T) top() inout {
      return p.back;
    }
  }

  ref inout(T) opIndex(size_t idx) inout {
    assert(!empty, "nep.container.Stack.opIndex: Stack is empty.");

    return (*p)[idx];
  }

  alias Range = RangeT!(StackPayload!T);
  alias ConstRange = RangeT!(const StackPayload!T);
  alias ImmutableRange = RangeT!(immutable StackPayload!T);

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

  void push(T value) {
    if (mayNull && !p) {
      p = new Payload();
    }

    p.insertBack(value);
  }

  void push(Stuff)(Stuff stuff)
      if (isImplicitlyConvertible!(Stuff, T) || isInputRange!Stuff
        && isImplicitlyConvertible!(ElementType!Stuff, T)) {
    foreach (e; stuff) {
      push(e);
    }
  }

  void opOpAssign(string op, Stuff)(Stuff stuff) if (op == "~") {
    static if (is(typeof(stuff[]))) {
      push(stuff[]);
    } else {
      push(stuff);
    }
  }

  void clear() {
    p.clear();
  }

  void pop() {
    assert(!mayNull || p, "nep.container.Stack.pop: Stack is empty.");

    p.popBack();
  }

  string toString() const {
    return !empty ? p.toString() : "[]";
  }
}

// unittest {{{
@system unittest {
  auto st = Stack!int();
  st ~= 1;
  st ~= 10;
  assert(st.top == 10);
  st.pop();
  assert(st.top == 1);
}

@system unittest {
  auto st = Stack!int();
  assert(st.empty);
}

@system unittest {
  import std.algorithm : equal;

  auto st = Stack!int([1, 2, 3, 4, 5]);

  assert(equal(st[], [1, 2, 3, 4, 5]));
  st ~= 6;
  assert(equal(st[], [1, 2, 3, 4, 5, 6]));

  st.clear();
  assert(st.empty);


  st ~= [2, 4, 6, 8, 10];
  assert(equal(st[], [2, 4, 6, 8, 10]));

  st[0 .. $] /= 2;
  assert(equal(st[], [1, 2, 3, 4, 5]));
  assert(equal(st[2 .. $], [3, 4, 5]));
}

@system unittest {
  import std.algorithm : equal;
  import std.range : iota;

  auto st = Stack!int(iota(0, 100));

  assert(equal(st[], iota(0, 100)));
}

@system unittest {
  import std.algorithm : equal;

  struct Test {
    this(int x) {
      _x = x;
    }
    int _x;
  }

  auto st = Stack!Test(Test(1), Test(2));
  assert(equal(st[], [Test(1), Test(2)]));
}
// }}}
