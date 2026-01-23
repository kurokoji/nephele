module nep.datastructure.unionfind;

struct UnionFind {
  private {
    size_t[] par_;
    size_t[] size_;
  }

  this(size_t n) {
    import std.range : iota, array;

    par_ = iota(n).array;

    size_ = new size_t[n];
    size_[0 .. $] = 1;
  }

  void merge(size_t x, size_t y) {
    import std.algorithm : swap;

    x = root(x);
    y = root(y);

    if (x != y) {
      if (size_[x] < size_[y]) {
        swap(x, y);
      }

      par_[y] = x;
      size_[x] += size_[y];
    }
  }

  bool isSame(size_t x, size_t y) {
    return root(x) == root(y);
  }

  size_t root(size_t x) {
    if (x == par_[x]) {
      return x;
    }

    par_[x] = root(par_[x]);
    return par_[x];
  }

  size_t size(int x) {
    return size_[root(x)];
  }
}

// unittest {{{
@system unittest {
  auto uf = UnionFind(5);

  uf.merge(0, 1);
  uf.merge(0, 2);
  uf.merge(3, 4);

  assert(uf.isSame(0, 2));
  assert(!uf.isSame(0, 3));
  assert(uf.size(0) == 3);
}
// }}}
