module nep.container.deque;

struct DequePayload(T, size_t pageSize = 8)
{
    import std.traits;
    import core.exception : RangeError;

    private
    {
        T[][] _data;
        size_t top, len, cap;
    }

    alias opDollar = length;
    alias opOpAssign(string op : "~") = insertBack;

    @property
    {
        size_t empty() const
        {
            return len == 0;
        }

        size_t length() const
        {
            return len;
        }

        ref inout(T) front() inout
        {
            return this[0];
        }

        ref inout(T) back() inout
        {
            return this[$ - 1];
        }
    }

    ref inout(T) opIndex(size_t idx) inout
    {
        if (len <= idx)
        {
            throw new RangeError();
        }

        if (top + idx < cap)
        {
            return _data[(top + idx) / pageSize][(top + idx) % pageSize];
        }

        return _data[(top + idx - cap) / pageSize][(top + idx - cap) % pageSize];
    }

    void reserve(size_t newCap)
    {
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

        foreach (i; 0 .. newArrSize - nowArrSize)
        {
            _data ~= new T[pageSize];
        }

        top = 0;
        cap = nextCap;
    }

    void insertBack(E)(E value) if (isImplicitlyConvertible!(E, T))
    {
        import std.algorithm : max;

        if (len == cap)
        {
            reserve(max(cap * 2 * pageSize, 4 * pageSize));
        }

        ++len;
        this[$ - 1] = value;
    }

    void popBack()
    {
        assert(!empty, "nep.container.Deque.removeBack: Deque is empty.");

        --len;
    }

    void clear()
    {
        top = 0;
        len = 0;
    }

    void insertFront(E)(E value) if (isImplicitlyConvertible!(E, T))
    {
        import std.algorithm : max;

        if (len == cap)
        {
            reserve(max(cap * 2 * pageSize, 4 * pageSize));
        }

        if (top == 0)
        {
            top += cap;
        }

        --top;
        ++len;
        this[0] = value;
    }

    void popFront()
    {
        assert(!empty, "nep.container.Deque.removeFront: Deque is empty.");

        ++top;
        --len;
        if (top == cap)
        {
            top = 0;
        }
    }

    string toString() const
    {
        import std.format : format;

        string ret = "[ ";
        foreach (i; 0 .. len)
        {
            ret ~= format("%s%s", this[i], i == len - 1 ? " ]" : ", ");
        }

        return ret;
    }
}

struct Deque(T, bool mayNull = true)
{
    import std.traits : isImplicitlyConvertible;
    import std.range : ElementType, isInputRange;
    import std.exception;

    alias Payload = DequePayload!T;
    alias opDollar = length;
    alias opOpAssign(string op : "~") = insertBack;

    private
    {
        Payload* p;
    }

    this(A)(A[] args...) if (isImplicitlyConvertible!(A, T))
    {
        p = new Payload();

        foreach (e; args)
        {
            p ~= e;
        }
    }

    @property
    {
        bool empty() const
        {
            return !(!mayNull || p) || p.empty;
        }

        size_t length() const
        {
            return !mayNull ? p.length : 0;
        }

        ref inout(T) front() inout
        {
            return p.front;
        }

        ref inout(T) back() inout
        {
            return p.back;
        }
    }

    ref inout(T) opIndex(size_t idx) inout
    {
        assert (!empty, "nep.container.deque.opIndex: Deque is empty.");

        return (*p)[idx];
    }

    void insertBack(T value)
    {
        if (mayNull && !p)
        {
            p = new Payload();
        }

        p.insertBack(value);
    }

    void popBack()
    {
        assert(!mayNull || p, "nep.container.deque.popFront: Deque is empty.");

        p.popBack();
    }

    void insertFront(T value)
    {
        if (mayNull && !p)
        {
            p = new Payload();
        }

        p.insertFront(value);
    }

    void popFront()
    {
        assert(!mayNull || p, "nep.container.deque.popFront: Deque is empty.");

        p.popFront();
    }

    void clear()
    {
        if (p)
        {
            p.clear();
        }
    }

    string toString() const
    {
        return !empty ? p.toString() : "[  ]";
    }
}

unittest
{
    auto dq = Deque!int();

    dq.insertBack(1);
    dq.insertFront(2);
    dq.insertBack(3);
    dq.insertFront(4);
    dq.insertBack(5);

    assert(dq.toString() == "[ 4, 2, 1, 3, 5 ]");
    dq.popBack();
    assert(dq.toString() == "[ 4, 2, 1, 3 ]");
    dq.insertBack(6);
    assert(dq.toString() == "[ 4, 2, 1, 3, 6 ]");
    dq.popFront();
    assert(dq.toString() == "[ 2, 1, 3, 6 ]");
    dq.insertFront(7);
    assert(dq.toString() == "[ 7, 2, 1, 3, 6 ]");
}
