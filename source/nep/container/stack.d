module nep.container.stack;

struct Stack(T, size_t minCapacity = 5) if (minCapacity >= 0) {
  import std.traits;
  import std.range.primitives;

  private {
    T* _data;
    size_t _capacity, _length;
  }

  alias opOpAssign(string op = "~") = insertBack;

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

    ref inout(T) back() inout {
      assert(_length != 0, "nep.container.Stack.top: Stack is empty");
      return _data[_length - 1];
    }

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

  void crear() {
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
    assert(_length != 0, "nep.container.Stack.pop: Stack is empty");
    --_length;
  }
}

@system unittest {
  import std.stdio : writeln;

  auto st = Stack!int();
  st ~= 1;
  st ~= 10;
  assert(st.back == 10);
  st.popBack();
  assert(st.back == 1);
}

@system unittest {
  auto st = Stack!int();
  assert(st.empty);
}
