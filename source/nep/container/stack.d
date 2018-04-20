module nep.container.stack;


struct Stack(T)
{
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

        void emplace()(const ref auto T value)
        {
            if (_length == _capacity)
            {
                if (_capacity < _minCapacity)
                {
                    reserve(_minCapacity);
                }
                else
                {
                    reserve(_capacity * 2);
                }
            }
            _data[_length++] = value;
        }

        void pop()
        {
            --_length;
        }
    }

}
