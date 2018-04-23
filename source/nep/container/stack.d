module nep.container.stack;


struct Stack(T)
{
    import std.traits;
    import std.range.primitives;

    private struct Payload(T, size_t _minCapacity = 5) if (_minCapacity >= 0)
    {
        private T* _data;
        private size_t _capacity, _length;

        alias opOpAssign(string op = "~") = emplace;

        ~this()
        {
            import core.memory : GC;
            if (_data != null)
            {
                GC.free(_data);
            }
        }

        @property size_t length() const
        {
            return _length;
        }

        @property size_t capacity() const
        {
            return _capacity;
        }

        @property bool empty() const
        {
            return _length == 0;
        }

        @property ref inout(T) top() inout
        {
            assert(_length == 0, "nep.container.Stack.top: Stack is empty");
            return _data[_length - 1];
        }

        void reserve(size_t newCapacity)
        {
            import core.memory : GC;
            import core.stdc.string : memcpy;

            if (_capacity >= newCapacity) return;

            T* newData = cast(T*)GC.malloc(T.sizeof * newCapacity);
            if (_length != 0) memcpy(newData, _data, _length * T.sizeof);
            _capacity = newCapacity;

            T* oldData = _data;
            _data = newData;
            GC.free(oldData);
        }

        void free()
        {
            import core.memory : GC;
            GC.free(_data);
            _length = 0;
            _capacity = 0;
        }

        void crear()
        {
            _length = 0;
        }

        void emplace(E)(const ref auto E value) if (isImplicitlyConvertible(E, T))
        {
            if (_length == _capacity)
            {
                if (_capacity < _minCapacity)
                {
                    reserve(_minCapacity);
                }
                else
                {
                    reserve(1 + _capacity * 3 / 2);
                }
            }
            _data[_length++] = value;
        }

        void pop()
        {
            assert(_length == 0, "nep.container.Stack.pop: Stack is empty");
            --_length;
        }
    }

    @system unittest
    {
        import std.stdio : writeln;
        auto st = Payload!int();
        st ~= 1;
        st ~= 10;
        assert(st.top == 10);
        st.pop();
        assert(st.top == 1);
    }

    @system unittest
    {
        auto st = Payload!int();
        assert(st.empty);
    }
}
