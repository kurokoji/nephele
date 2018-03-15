module nep.scanner;


class Scanner {
  import std.stdio;
  import std.conv : to;
  import std.array : split;
  import std.string : chomp;

  private File file;
  private char[][] str;
  private size_t idx;

  this(File file = stdin) {
    this.file = file;
    this.idx = 0;
  }

  private char[] next() {
    if (idx < str.length) {
      return str[idx++];
    }

    char[] s;
    while (s.length == 0) {
      s = file.readln.chomp.to!(char[]);
    }

    str = s.split;
    idx = 0;

    return str[idx++];
  }

  T next(T)() {
    return next.to!(T);
  }

  T[] nextArray(T)(size_t len) {
    T[] ret = new T[len];

    foreach (ref c; ret) {
      c = next!(T);
    }

    return ret;
  }

  void scan()() {}
  void scan(T, S...)(ref T x, ref S args) {
    x = next!(T);
    scan(args);
  }
}

unittest {
  import std.stdio;
  auto file = File("./tst.txt", "r");
  auto cin = new Scanner(file);
  int n = cin.next!int;
  int[] ar = cin.nextArray!int(n);
  assert(n == 4);
  assert(ar == [1, 2, 3, 45]);
  n = cin.next!int;
  ar = cin.nextArray!int(n);
  assert(n == 4);
  assert(ar == [1, 2, 3, 45]);
  int x, y, z;
  string s;
  cin.scan(x, y, z, s);
  assert(x == 1 && y == 2 && z == 3 && s == "tst");
}
