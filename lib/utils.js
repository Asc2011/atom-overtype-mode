var A, Point, Range, emptyR, log, p1, p2, p3, r1, r2, r3, ref;

ref = require('atom'), Point = ref.Point, Range = ref.Range;

log = console.log;

Point.prototype.add = function(PorA) {
  var column, ref1, ref2, ref3, ref4, ref5, row;
  if (PorA == null) {
    PorA = [0, 0];
  }
  try {
    if (Array.isArray(PorA)) {
      row = PorA[0], column = (ref1 = PorA[1]) != null ? ref1 : 0;
    } else if (arguments.length > 1) {
      row = (ref2 = arguments[0]) != null ? ref2 : 0, column = (ref3 = arguments[1]) != null ? ref3 : 0;
    } else {
      row = (ref4 = PorA.row) != null ? ref4 : 0, column = (ref5 = PorA.column) != null ? ref5 : 0;
    }
    this.row += +row;
    this.column += +column;
  } catch (error) {}
  return this;
};

Point.prototype.sub = function(PorA) {
  var column, ref1, ref2, ref3, ref4, ref5, row;
  if (PorA == null) {
    PorA = [0, 0];
  }
  try {
    if (Array.isArray(PorA)) {
      row = PorA[0], column = (ref1 = PorA[1]) != null ? ref1 : 0;
    } else if (arguments.length > 1) {
      row = (ref2 = arguments[0]) != null ? ref2 : 0, column = (ref3 = arguments[1]) != null ? ref3 : 0;
    } else {
      row = (ref4 = PorA.row) != null ? ref4 : 0, column = (ref5 = PorA.column) != null ? ref5 : 0;
    }
    this.row -= +row;
    this.column -= +column;
  } catch (error) {}
  return this;
};

Point.prototype.incC = function() {
  this.column++;
  return this;
};

Point.prototype.incR = function() {
  this.row++;
  return this;
};

Point.prototype.decC = function() {
  this.column--;
  return this;
};

Point.prototype.decR = function() {
  this.row--;
  return this;
};

Point.prototype.toString = function() {
  return "P({@row}," + this.column + ")";
};

Range.prototype.incSC = function() {
  this.start.incC();
  return this;
};

Range.prototype.incSR = function() {
  this.start.incR();
  return this;
};

Range.prototype.incEC = function() {
  this.end.incC();
  return this;
};

Range.prototype.incER = function() {
  this.end.incR();
  return this;
};

Range.prototype.decSC = function() {
  this.start.decC();
  return this;
};

Range.prototype.decSR = function() {
  this.start.decR();
  return this;
};

Range.prototype.decEC = function() {
  this.end.decC();
  return this;
};

Range.prototype.decER = function() {
  this.end.decR();
  return this;
};

Range.prototype.inc = function() {
  this.end.column++;
  return this;
};

Range.prototype.toString = "Ra(" + (this.start - this.end) + ")";

A = {
  p: function(PorA) {
    var column, ref1, ref2, ref3, ref4, ref5, row;
    if (PorA == null) {
      PorA = [0, 0];
    }
    try {
      if (Array.isArray(PorA)) {
        row = PorA[0], column = (ref1 = PorA[1]) != null ? ref1 : 0;
      } else if (arguments.length > 1) {
        row = (ref2 = arguments[0]) != null ? ref2 : 0, column = (ref3 = arguments[1]) != null ? ref3 : 0;
      } else {
        row = (ref4 = PorA.row) != null ? ref4 : 0, column = (ref5 = PorA.column) != null ? ref5 : 0;
      }
      return new Point(row, column);
    } catch (error) {}
  },
  r: function(PorA) {
    var ec, er, p1, p2, ref1, ref2, ref3, ref4, sc, sr;
    if (PorA == null) {
      PorA = [0, 0, 0, 0];
    }
    try {
      if (arguments.length === 4) {
        sr = (ref1 = arguments[0]) != null ? ref1 : 0, sc = (ref2 = arguments[1]) != null ? ref2 : 0, er = (ref3 = arguments[2]) != null ? ref3 : 0, ec = (ref4 = arguments[3]) != null ? ref4 : 0;
        return new Range(A.p(sr, sc), A.p(er, ec));
      } else if (arguments.length === 2) {
        p1 = arguments[0], p2 = arguments[1];
        if ((p1 instanceof Point) && (p2 instanceof Point)) {
          return new Range(p1, p2);
        } else if (Array.isArray(p1) && Array.isArray(p2)) {
          return new Range(A.p(p1), A.p(p2));
        }
      } else if (arguments.length === 1) {
        return A.r(arguments[0]);
      }
    } catch (error) {}
  }
};

p1 = A.p(1, 5);

p2 = A.p([2, 10]);

p3 = A.p({
  row: 3,
  column: 15
});

log(p1);

log(p2);

log(p3);

p1.add(p2);

log('p1 + p2 == p3', p1.isEqual(p3));

log('p1', p1);

log('p3', p3);

r1 = A.r(p2, p3);

log('r1', r1);

r2 = A.r(1, 1, 2, 2);

r3 = A.r([1, 1], [2, 2]);

log('r2', r2, '\n', 'r3', r3);

log('r2 == r3', (r2.start.isEqual(r3.start)) && (r2.end.isEqual(r3.end)));

log('r3.inc', r3.inc());

emptyR = A.r(1, 1, 1, 1);

log("empty-range is empty", emptyR.isEmpty());

emptyR.inc();

log("empty-range after inc is empty ?", emptyR.isEmpty());

module.exports = {
  Point: Point,
  Range: Range,
  A: A
};
