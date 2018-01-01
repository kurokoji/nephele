module tbh.scanner;


class Scanner {
  import std.stdio;
  import std.conv : to;
  import std.array : split;
  import std.string : chomp;

  private File file;
  private dchar[][] str;
  private uint idx;

  this(File file = stdin) {
    this.file = file;
    this.idx = 0;
  }

  private dchar[] next() {
    if (idx < str.length) {
      return str[idx++];
    }

    dchar[] s;
    while (s.length == 0) {
      s = file.readln.chomp.to!(dchar[]);
    }

    str = s.split;
    idx = 0;

    return str[idx++];
  }

  T next(T)() {
    return next.to!(T);
  }

  T[] next(T : T[])(uint len) {
    T[] ret = new T[len];

    foreach (ref c; ret) {
      c = next!(T);
    }

    return ret;
  }
}

unittest {
  import std.stdio;
  auto file = File("./tst.txt", "r");
  auto cin = new Scanner(file);
  int n = cin.next!int;
  int[] ar = cin.next!(int[])(n);
  assert(n == 4);
  assert(ar == [1, 2, 3, 45]);
  n = cin.next!int;
  ar = cin.next!(int[])(n);
  assert(n == 4);
  assert(ar == [1, 2, 3, 45]);
}
