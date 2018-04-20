module nep.container.stack;


struct Stack(T)
{
    private struct Payload(T, size_t _minCapacity = 5) if (_minCapacity >= 0)
    {
        private T* _data;
        private size_t _capacity, _length;

        ~this()
        {
            import core.memory : GC;
            if (_data != null)
            {
                GC.free(_data);
            }
        }
    }

}
