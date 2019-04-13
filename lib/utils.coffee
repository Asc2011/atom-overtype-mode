{ Point, Range } = require 'atom'
log = console.log 

Point::add = ( PorA=[ 0,0 ] ) ->
  try
    if Array.isArray PorA
      [row, column=0] = PorA
    else if arguments.length > 1
      [row=0, column=0] = arguments
    else
      { row=0, column=0 } = PorA
      
    @row    += +row
    @column += +column
  @


Point::sub = ( PorA=[ 0,0] ) ->
  try
    if Array.isArray PorA
      [row, column=0] = PorA
    else if arguments.length > 1
      [row=0, column=0] = arguments
    else
      { row=0, column=0 } = PorA
    
    @row    -= +row
    @column -= +column
  @

Point::incC = -> @column++; @
Point::incR = -> @row++; @
Point::decC = -> @column--; @
Point::decR = -> @row--; @
Point::toString = -> "P({@row},#{@column})"

Range::incSC = -> @start.incC(); @
Range::incSR = -> @start.incR(); @
Range::incEC = -> @end.incC();   @
Range::incER = -> @end.incR();   @
Range::decSC = -> @start.decC(); @
Range::decSR = -> @start.decR(); @
Range::decEC = -> @end.decC();   @
Range::decER = -> @end.decR();   @
Range::inc = -> @end.column++; @  

Range::toString = "Ra(#{@start-@end})"

A = {
  p : ( PorA=[ 0,0 ] ) ->
    try
      if Array.isArray PorA
        [row, column=0] = PorA
      else if arguments.length > 1
        [row=0, column=0] = arguments
      else
        { row=0, column=0 } = PorA

      new Point row, column
      
  r : ( PorA=[0,0,0,0] ) ->
    try
      if arguments.length is 4
        [ sr=0, sc=0, er=0, ec=0 ] = arguments
        return new Range A.p(sr,sc), A.p(er, ec)
        
      else if arguments.length is 2
        [p1, p2] = arguments
        if (p1 instanceof Point) and (p2 instanceof Point)
          return new Range p1, p2
        else if Array.isArray(p1) and Array.isArray(p2)
          return new Range A.p(p1), A.p(p2)
          
      else if arguments.length is 1
        return A.r arguments[0]
}

# Test

p1 = A.p 1,5
p2 = A.p [2,10]
p3 = A.p { row: 3, column: 15}

log p1
log p2
log p3

p1.add p2 
log 'p1 + p2 == p3', p1.isEqual p3
log 'p1', p1
log 'p3', p3

r1 = A.r p2, p3
log 'r1', r1
r2 = A.r  1, 1, 2, 2
r3 = A.r [ 1, 1 ], [ 2, 2 ]
log 'r2', r2, '\n', 'r3', r3
log 'r2 == r3', (r2.start.isEqual r3.start) and (r2.end.isEqual r3.end)
log 'r3.inc',  r3.inc()
emptyR = A.r 1,1,1,1
log "empty-range is empty", emptyR.isEmpty()
emptyR.inc() 
log "empty-range after inc is empty ?
", emptyR.isEmpty()


module.exports = { Point, Range, A }
