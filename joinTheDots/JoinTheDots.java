//------------------------------------------------------------------------------
// https://open.kattis.com/problems/connectdots  9.6
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2022
//------------------------------------------------------------------------------
import java.util.*;
import java.io.*;

class JoinTheDots
 {final static boolean debug = true;                                            // Debugging if true
  final static Scanner S = new Scanner(System.in);                              // The input problem
  final static int     N = 4;                                                   // The size of the problem
  final static int [][]array  = new int[N][N];                                  // Layout of the point numbers
  final static TreeMap<Integer, Point> map = new TreeMap<>();                   // Point number to coordinates

  static class Point                                                            // A point on the grid
   {final static double limit = 10e-6;                                          // Limit of closeness
    double x, y;                                                                // X, Y coordinates of point

    Point               (double x, double y) {this.x = x; this.y = y;}          // Create a point
    static boolean close(double a, double b) {return Math.abs(a - b) < limit;}  // Whether two numbers are close together
    static boolean zero (double a)           {return Math.abs(a)     < limit;}  // Whether a number so close to zero
    static boolean le   (double a, double b) {return a <  b + limit;}           // Whether a number is less than or eqaul to a number
    static boolean ge   (double a, double b) {return a >  b - limit;}           // Whether a number is greater than or equal to a number
    double      len()         {return Math.hypot(x, y);}                        // The length of a vector
    double      dot(Point  a) {return x * a.x + y * a.y;}                       // Dot product between two vectors
    double distance(Point  a) {return this.sub(a).len();}                       // Distance between two points
    Point       add(Point  a) {return P(x + a.x, y + a.y);}                     // Add two vectors
    Point       sub(Point  a) {return P(x - a.x, y - a.y);}                     // Subtract two vectors
    Point       mul(double s) {return P(x * s, y * s);}                         // Multiply a vector by a scalar
    Point       div(double s) {return P(x / s, y / s);}                         // Divide a vector by a scalar
    Point normalize()         {return div(len());}                              // Normalize a vector
    Point normalize(double s) {return normalize().mul(s);}                      // Normalize a vector and multiply the result by a scalar to get a vector of a specified length pointing along the original vector
    Point       r90()         {return new Point(-y, x);}                        // Rotate a vector by 90 degrees clockwise
    Point   reflect(Point r)  {return sub(r.sub(this));}                        // Reflect a point in this point
    boolean    zero()         {return zero(len());}                             // Whether a vector is the zero vector
    boolean      eq(Point  a) {return zero(distance(a));}                       // Whether two vectors are equal
    boolean     col(Point  a) {return schwartz(P(0,0), a);}                     // Whether two vectors are colinear
    double    cross(Point  a) {return x * a.y - y * a.x;}                       // 2 dimensional cross product - the area of the parallelogram contained by the vectors

    Double      div(Point  a)                                                   // Divide two colinear vectors to get a scalar
     {if (zero(a.x) && zero(a.y)) return null;                                  // Cannot divide by zero
      if (!col(a)) return null;                                                 // Not colinear
      if (zero(a.x)) return y / a.y;                                            // Divide
      return x / a.x;
     }

    boolean schwartz(Point A, Point B)                                          // Schwartz inequality - return true if the points are collinear
     {final Point C = this;
      if (Point.close(A.distance(B)+B.distance(C), A.distance(C))) return true;
      if (Point.close(B.distance(C)+C.distance(A), B.distance(A))) return true;
      if (Point.close(C.distance(A)+A.distance(B), C.distance(B))) return true;
      return false;
     }

    public String toString() {return "P("+x+","+y+")\n";}
   }

  static Point P(double a, double b) {return new Point(a, b);}                  // Shorthand for creating a point

  static class Line                                                             // A two dimensional line nominally directed from its first point through its second point
   {final Point start, end;                                                     // Start and end points of line segment

    Line(Point start, Point end)                                                // New line made from two points
     {assert !start.eq(end);
      this.start = start;
      this.end   = end;
     }

    public String toString()
     {return String.format("L(%s,%s)\n", start, end);
     }

    Point    s() {return start;}                                                // The point at the start of the line
    Point    e() {return end;}                                                  // The point at the end   of the line
    Point    d() {return e().sub(s());}                                         // The vector along the line from start to end
    double len() {return d().len();}                                            // Length of the line segment
    boolean parallel(Line l) {return d().col(l.d());}                           // Parallel lines

    int side(Point x)                                                           // The side of the line the point is on A expressed as -1, 0, +1
     {final double c = d().cross(x.sub(s()));                                   // Cross
      return Point.zero(c) ? 0 : c > 0 ? +1 : -1;
     }

    boolean along(Point x)                                                      // Check if this point is on the line extended from its start through its end
     {if (!s().schwartz(e(), x)) return false;                                  // Not colinear
      return x.sub(s()).div(d()) >= 0;
     }

    boolean goesTo(Point X)                                                     // Check that the point X is on the specified line and beyond the end point of the defining segment
     {if (!s().schwartz(e(), X)) return false;                                  // Not colinear
      return X.sub(s()).div(d()) >= 1;
     }

    Point intersection(Line X)                                                  // Locate the point, if any, at which this line intersects another line
     {final Point a = s(), b = e(), c = X.s(), d = X.e();

      if (parallel(X)) return null;                                             // Parallel lines do not intersect

      if (Point.zero(b.sub(a).dot(d.sub(c))))                                   // Orthogonal
       {final Point radius = c.sub(a).div(2);
        final double r = radius.len();
        final Point A = b.sub(a),  B = a.sub(c).div(2);
        final double D = A.dot(A), E = A.dot(B)*2, F = B.dot(B) - radius.dot(radius);
        final double l1 = (-E + Math.sqrt(E*E-4*D*F)) / (2 * D);
        final double l2 = (-E - Math.sqrt(E*E-4*D*F)) / (2 * D);
        final Point i = a.add(b.sub(a).mul(Math.abs(l1) > Math.abs(l2) ? l1 : l2));
        return i;
       }

      if (a.x != b.x && a.y != b.y)
       {final double Ax = (c.x-a.x)/(b.x-a.x), Ay = (c.y-a.y)/(b.y-a.y),
                     Bx = (d.x-c.x)/(b.x-a.x), By = (d.y-c.y)/(b.y-a.y),
          m = (Ax - Ay) / (By - Bx);

        return c.add(d.sub(c).mul(m));
       }

      if (c.x != d.x && c.y != d.y)
       {final double Cx = (a.x-c.x)/(d.x-c.x), Cy = (a.y-c.y)/(d.y-c.y),
                     Dx = (b.x-a.x)/(d.x-c.x), Dy = (b.y-a.y)/(d.y-c.y),
          l = (Cx - Cy) / (Dy - Dx);
        return a.add(b.sub(a).mul(l));
       }

      stop("Intersection needs more code for: ", a, b, c, d);
      return null;
     }
   }

  static Line L(Point a, Point b) {return new Line(a, b);}                      // New line

  static class Sector                                                           // A sector of the board with the area of interest always to the anti clockwise of A. If the arms A and B are colinear than every where is accessible.  If  B is null then we have a straight line along A.
   {final Point O, A, B;                                                        // Origin of sector, arms of sector represented as points not as vectors relative to the origin
    final boolean ia, ib;                                                       // Whether to include the edges or not

    Sector(Point origin)                                                        // All
     {this(origin, null, null, true, true);
     }

    Sector(Point origin, Point A)                                               // Line
     {this(origin, A, null, true, true);
     }

    Sector(Point origin, Point A, Point B, boolean ia, boolean ib)              // Angle
     {this.O  = origin;
      this.A  = A;
      this.B  = B;
      this.ia = ia;
      this.ib = ib;
     }

    boolean all  () {return A == null && B == null;}                            // All of the board?
    boolean line () {return A != null && B == null;}                            // Is this a line sector?
    boolean angle() {return A != null && B != null;}                            // Is this sector an angle?
    boolean small() {return L(O, A).side(B) == 1;}                              // Is this sector small?
    boolean big()   {return L(O, A).side(B) != 1;}                              // Is this sector big?

    public String toString()                                                    // Is this sector equal to the specified sector
     {if (angle()) return "\n(angle,\n "+O+","+A+","+B+","+(ia ? "1":"0")+(ib ? "1":"0")+" "+(small()?"small" : "big")+")\n";
      if (line())  return "\n(line "+O+","+A+")\n";
      return "\n(all  "+O+")\n";
     }

    boolean eq(Sector X)                                                        // Is this sector equal to the specified sector?
     {return O.eq(X.O) && A.eq(X.A) && B.eq(X.B) && ia == X.ia && ib == X.ib && small() == X.small();
     }

    Sector translate(Point X)                                                   // Translate to the specified point
     {return new Sector(X, A != null ? A.add(X.sub(O)) : null,
                           B != null ? B.add(X.sub(O)) : null, ia, ib);
     }

    boolean contains(Point X)                                                   // Does the sector contain the specified point
     {if (all())   return true;                                                 // All contains everything

      if (line())  return L(O, A).along(X);                                     // Line only contains things along the line

      if (L(O, A).along(X)) return ia;                                          // On A arm
      if (L(O, B).along(X)) return ib;                                          // On B arm
      if (L(O, A).side(B) > 0)                                                  // B is to the left so we have a small sector
       {return L(O, A).side(X) > 0 && L(O, B).side(X) < 0;                      // In the small sector
       }
      return   L(O, A).side(X) > 0 || L(O, B).side(X) < 0;                      // In the large sector
     }

    Sector repoint(Point X)                                                     // Create a new sector with the specified O that accepts the Oal sector
     {if (all())  return new Sector(X, null, null, true, true);                 // All can reach any point through X

      if (line())
       {switch(L(O, A).side(X))
         {case +1 : return new Sector(X, X.reflect(O), X.sub(A.sub(O)), true, false);
          case -1 : return new Sector(X, X.sub(A.sub(O)), X.reflect(O), false, true);
          default : return new Sector(X, X.reflect(O), null, true, true);
         }
       }

      if (L(O, A).along(X))                                                     // X is along arm A
       {if (ia) return new Sector(X, null, null, true, true);                   // X is on arm A and A is included so we can reach any point
        return new Sector(X, O, X.reflect(O), false, false);
       }

      if (L(O, B).along(X))                                                     // X is along arm B
       {if (ib) return new Sector(X, null, null, true, true);                   // X is on arm B and B is included so we can reach any point
        return new Sector(X, X.reflect(O), O, false, false);
       }

      final Point iA = L(A, X).intersection(L(O, B));                           // Line from A intersects B so connector is outside A
      if (iA != null && L(O, B).along(iA) && L(A, iA).along(X))
       {return new Sector(X, X.reflect(O), X.sub(B.sub(O)), true, false);
       }

      final Point iB = L(B, X).intersection(L(O, A));                           // Line from B intersects A so connector is outside B
      if (iB != null && L(O, A).along(iB) && L(B, iB).along(X))
       {return new Sector(X, X.sub(A.sub(O)), X.reflect(O), false, true);
       }

      return new Sector(X, X.sub(A.sub(O)), X.sub(B.sub(O)), false, false);     // No edge effects
     }
   }

  static class Drawing                                                          // The draws necessary to pass through all the points
   {final TreeMap<Integer,Draw> path = new TreeMap<>();

    static class Draw                                                           // One drawn line
     {Sector sector = null;                                                     // The current sector
      boolean newLine = true;                                                   // Started a new line
      boolean in = false;                                                       // True if known to be in the segment

      public String toString()
       {return "\n"+(newLine ? " new " : " ___ ")
         +(in ? "  in " :
                " out " )+sector+"\n";
       }
     }

    Drawing()                                                                   // New drawing with a draw through each point
     {for (int i = 0; i <= N*N; i++) path.put(i, new Draw());

      path.get(1)    .in      = true;                                           // Start and end conditions
      path.get(1)    .newLine = true;
      path.get(N*N-1).in      = true;
      path.get(N*N)  .in      = true;
      path.get(N*N)  .newLine = false;

      for (int i = 1; i+2 <= N*N; i++)                                          // Three in a line
       {final Point A =  map.get(i), B =  map.get(i+1), C =  map.get(i+2);
        final Draw  a = path.get(i), b = path.get(i+1), c = path.get(i+2);

        if (A.schwartz(B, C) && L(A, B).goesTo(C))                              // Three in a line is always fine
         {a.in = b.in = true; b.newLine = false;
         }
       }

      path.get(1)    .newLine = true;                                           // In case we overrode the start position
      for (int i = 1; i+1 <= N*N; i++)
       {final Point A =  map.get(i), B =  map.get(i+1), C =  map.get(i+2);
        final Draw  a = path.get(i), b = path.get(i+1), c = path.get(i+2);
        if (a.in && !b.in)                                                      // Extend an in segment to an out segment
         {b.sector = new Sector(B, B.reflect(A));
         }

        else if (!a.in)                                                         // Extend an out segment to an out segment
         {b.sector = a.sector.repoint(B);
          if (b.sector.contains(C))                                             // Earth the sector if possible
           {b.newLine = false; b.in = true;
            if (!c.in)                                                          // Reset sector of downstream
             {c.sector = new Sector(C, C.reflect(B));
             }
           }
         }
       }
     }

    int pathLength()                                                            // Length in new lines of a path
     {int n = 0;
      for (int i = 1; i < N*N; i++)
       {final Draw d = path.get(i);
        if (d.newLine) ++n;
       }
      return n;
     }

    char b(boolean b)                                                           // Boolean to char
     {return b ? 'T' : 'f';
     }

    void printDraws(TreeMap<Integer,Draw> D)                                    // Print the current path
     {say("Path length is:", pathLength());
      for (int i = 1; i <= N*N; i++)
       {Draw   d = D.get(i);
        Sector s = d.sector;
        Point  p = map.get(i);
        if (s == null) s = new Sector(P(0,0));
        if (s.all  ()) say(String.format(" %2d | %c | %c  %2.0f  %2.0f | All   |                                           |",         i, b(d.in), b(d.newLine), p.x, p.y));
        if (s.line ()) say(String.format(" %2d | %c | %c  %2.0f  %2.0f | Line  | %2.0f  %2.0f | %2.0f  %2.0f |             |",         i, b(d.in), b(d.newLine), p.x, p.y, s.O.x, s.O.y, s.A.x, s.A.y));
        if (s.angle()) say(String.format(" %2d | %c | %c  %2.0f  %2.0f | Angle | %2.0f  %2.0f | %2.0f  %2.0f  %c | %2.0f  %2.0f %c |", i, b(d.in), b(d.newLine), p.x, p.y, s.O.x, s.O.y, s.A.x, s.A.y, b(s.ia), s.B.x, s.B.y, b(s.ib)));
       }
     }
   }

  static double sx(double d) {return 600 + d       * 200;}                      // Transform x square to pixel
  static double sy(double d) {return 100 + (N - d) * 200;}                      // Transform y square to pixel

  static void line(FileWriter w, String cls,                                    // Draw a line
    double x, double y, double X, double Y) throws Exception
   {w.write(String.format
    ("<line class='%s' x1='%f' y1='%f' x2='%f' y2='%f'/>\n",
     cls, sx(x), sy(y), sx(X), sy(Y)));
   }

  static void line(FileWriter w, String cls, Point a, Point b)
    throws Exception
   {line(w, cls, a.x, a.y, b.x, b.y);
   }

  static void draw(String name, Drawing drawing, String expected)               // Draw the lines through the points
    throws Exception
   {final TreeMap<Integer, Drawing.Draw> path = drawing.path;

    final FileWriter w = new FileWriter("drawings/"+name+".svg");                  
    w.write("""
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg>
<svg xmlns="http://www.w3.org/2000/svg" width="2000" height="1000">
  <style>
    .title {
      font-size: 200%;
      font-weight: bold;
      stroke: darkred;
      fill  : darkred;
    }
    .expected {
      font-size: 150%;
      font-weight: bold;
      stroke: darkblue;
      fill  : darkblue;
    }
    .count, .squareNumber {
      font-size: 180%;
      font-weight: bold;
      stroke: darkgreen;
      fill  : darkgreen;
    }
    .in {
      stroke: green;
      stroke-width: 8;
    }
    .out {
      stroke: pink;
      stroke-width: 8;
    }
    .position {
      font-size: 150%;
    }
    .newLine {
      stroke: black;
      fill: silver;
    }
    .lineNumberStart {
      font-size: 150%;
      font-weight: bold;
      stroke: darkgreen;
      fill: darkgreen;
    }
    .lineNumberContinue {
      font-size: 120%;
      stroke: darkblue;
      fill: darkblue;
    }
    .sectorLine {
      stroke: darkOrange;
      stroke-width     : 8;
      stroke-dasharray : 4 3;
    }
    .sectorA {
      stroke: green;
      stroke-width     : 4;
      stroke-dasharray : 3 2;
    }
    .sectorB {
      stroke: red;
      stroke-width     : 4;
      stroke-dasharray : 3 1;
    }
    .sectorN {
      stroke: blue;
      stroke-width     : 4;
      stroke-dasharray : 4 2;
    }
    .number {
      text-align: right;
    }
    #legend {
    }
   .segmentNumber     {color: darkRed}
   .segmentIn         {color: darkBlue}
   .segmentNewLine    {color: darkGreen}
   .segmentPx         {color: darkOrange}
   .segmentPy         {color: darkOrange}
   .segmentOx         {color: darkgoldenrod}
   .segmentOy         {color: darkgoldenrod}
   .segmentAx         {color: darkViolet}
   .segmentAy         {color: darkViolet}
   .segmentBx         {color: darkmagenta}
   .segmentBy         {color: darkmagenta}
   .segmentIA         {color: green}
   .segmentIB         {color: blue}

  </style>
  <rect stroke='#ddd' fill-opacity='0' width='2000' height='1000' x='0' y='0'></rect>
""");
    final String ts = new Date().toString();
    w.write("<text stroke='#000' x='040' y='020'>"+ts+"</text>");               // Time

    w.write("<text class='title'    stroke='#000' x='100' y='100'>"+name    +"</text>");         // Title
    w.write("<text class='expected' stroke='#000' x='100' y='140'>"+expected+"</text>");         // Parameters
    w.write(String.format("<text class='count' fill='#000' x='100' y='180'>Draws = %d</text>",
      drawing.pathLength()));

    for (int i = 2; i <= N*N; i++)                                              // Draw each line
     {final Point    A = map.get(i-1), B = map.get(i);
      final Drawing.Draw a = path.get(i-1), b = path.get(i);
      final String cls = a.in ? "in" :"out";
      line(w, cls, A, B);                                                       // Line between points
     }

    for   (int i = 0; i < N; i++)                                               // Squares
     {for (int j = 0; j < N; j++)
       {final int    p = array[N-1-i][j];
        final Point  P = map.get(p);
        Drawing.Draw d = path.get(p);

        w.write(String.format("<rect stroke='#000' fill-opacity='0' width='200' height='200' x='%f' y='%f'></rect>\n",
                sx(j), sy(i+1)));
        w.write(String.format                                                   // Square number
         ("<text class='squareNumber' x='%f' y='%f'>%d</text>\n",
           sx(j)+160, sy(i+1)+25, p));

        if (d.newLine)                                                          // New Line requested
         {final double x = sx(P.x), y = sy(P.y);
          w.write(String.format(
           "<rect class='newLine' width='16' height='16' x='%f' y='%f'></rect>\n",
            x-8, y-8));
         }
       }
     }

    int draws = 0;                                                              // Number of lines drawn
    final Stack<String> h = new Stack<>();                                      // Html table showing legend

    for (int i = 1; i <= N*N; i++)                                              // Each Draw
     {Drawing.Draw d = path.get(i);
      Sector       s = d.sector;
      final Point  p = map.get(i);
      if (d.newLine) ++draws;

      final int offset = 20;                                                    // Line draw number
      final String lnc = d.newLine ? "Start" : "Continue";
      w.write(String.format
       ("<text class='lineNumber%s' x='%f' y='%f'>  %d</text>\n",
        lnc, sx(p.x)+offset, sy(p.y), draws));

      if (s != null)
       {if (s.angle())                                                          // Sector - angle
         {final Point o = s.O, a = s.A, b = s.B,
            A = o.add(a.sub(o).normalize(0.45)),
            B = o.add(b.sub(o).normalize(0.45)),
            C = o.schwartz(a, b) ? o.sub(a.sub(o).r90().normalize(0.3)) :
                                   o.add(A.sub(o).add(B.sub(o)).normalize(0.3)),
            R = s.small() ? C : o.reflect(C);
          line(w, "sectorA", o, A);
          line(w, "sectorB", o, B);
          line(w, "sectorN", o, R);
         }
        else if (s.line())                                                      // Sector line
         {final Point o = s.O, a = s.A, C = o.add(a.sub(o).normalize(0.3));
          line(w, "sectorLine", o, C);
         }
        else if (s.all())                                                       // Sector all
         {final Point o = s.O;
          w.write(String.format("<circle stroke='#000' fill-opacity='0' cx='%f' cy='%f' r='20'></circle>\n",
           sx(o.x), sy(o.y)));
         }
       }

      if (true)                                                                 //Legend
       {h.push("<tr>");
        h.push("<td class='number segmentNumber'> "+i+"</td>\n");
        h.push("<td class='segmentIn'>"     +(d.in      ? "in"  : "")+"</td>\n");
        h.push("<td class='segmentNewLine'>"+(d.newLine ? "new" : "")+"</td>\n");
        h.push("<td class='number segmentPx'>"     +String.format("%.0f", p.x)+"</td>\n");
        h.push("<td class='number segmentPy'>"     +String.format("%.0f", p.y)+"</td>\n");
        if (s != null)
         {h.push("<td class='number segmentOx'>"   + String.format("%.0f", s.O.x)+"</td>\n");
          h.push("<td class='number segmentOy'>"   + String.format("%.0f", s.O.y)+"</td>\n");

          if (s.A != null)
           {h.push("<td class='number segmentAx'>" + String.format("%.0f", s.A.x)+"</td>\n");
            h.push("<td class='number segmentAy'>" + String.format("%.0f", s.A.y)+"</td>\n");
           }
          else h.push("<td></td><td></td>");

          if (s.B != null)
           {h.push("<td class='number segmentBx'>" + String.format("%.0f", s.B.x)+"</td>\n");
            h.push("<td class='number segmentBy'>" + String.format("%.0f", s.B.y)+"</td>\n");
           }
          else h.push("<td></td><td></td>");

          h.push("<td class='segmentIA'>"   +(s.ia ? "on" : "")+"</td>\n");
          h.push("<td class='segmentIB'>"   +(s.ib ? "on" : "")+"</td>\n");
         }
        else h.push("<td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td>");
        h.push("</tr>");
       }
     }

    w.write("<foreignObject width='100%' height='100%' x='100' y='250'>");
    w.write("<div xmlns='http://www.w3.org/1999/xhtml'>");
    w.write("<table id='legend' border='1' cellspacing='5' cellpadding='5'>");
    w.write("<tr><th>#</th><th>In</th><th>New</th><th colspan='2'>Point</th><th colspan='2'>Origin</th><th colspan='2'>A</th><th colspan='2'>B</th><th>iA</th><th>iB</th></tr>");
    for (int i = 0; i < h.size(); i++) w.write(h.get(i));
    w.write("</table>");
    w.write("</div>");
    w.write("</foreignObject>");
    w.write("</svg>");
    w.close();
   }

  public static void main(String[] args) throws Exception                       // Main
   {if (debug) test();

    for   (int i = 0; i < N; i++)                                               // Load point numbers
     {for (int j = 0; j < N; j++)
       {int p = array[i][j] = S.nextInt();
        map.put(p, P(j+1, N - i));
       }
     }

    final Drawing drawing = new Drawing();                                      // Drawing
    System.out.println(drawing.pathLength());                                   // The answer

    if (debug)                                                                  // Draw the result
     {final StringBuilder e = new StringBuilder();
      for(String s: args)
       {if (s.matches(".*(TEST|--stop).*") || s == args[1]) continue;
        e.append(s);
       }
      draw(args[1], drawing, e.toString());
     }
   }

  static void test()                                                            // Tests
   {testPoints();
    testLines();
    testSectors();
   }

  static void testSectors()
   {testSectors1();
    testSectors2();
    testSectors3();
    testSectors4();
    testSectors5();
   }

  static void testSectors1()                                                    // 58325.svg
   {final Sector s = new Sector(P(4,3) ,P(6,1),P(7,2),false, true),
                 t =  s.repoint(P(4,2));
    assert t.eq(new Sector(P(4,2), P(2,4), P(4,1), false, true));
   }

  static void testSectors2()
   {final Sector s = new Sector(P(2,4),P(1,6),null, true, true),
                 t = s.repoint(P(1,1));
    assert !t.eq(new Sector(P(1,1),P(2,-1),P(0,-2), false, true));
    assert  t.eq(new Sector(P(1,1),P(0,-2),P(2,-1), true, false));
   }

  static void testSectors3()
   {final Sector s = new Sector(P(-1,+2),P(-2,+4),P(-3,+1), true, true);
    assert s.repoint(P( 0,-1)).eq(new Sector(P(0,-1),P(1,-4),P(2,0),true, false));
    assert s.repoint(P( 1, 0)).eq(new Sector(P(1, 0),P(2,-2),P(3,1),false,false));
    assert s.repoint(P( 2, 2)).eq(new Sector(P(2, 2),P(3,+0),P(4,3),false,false));
    assert s.repoint(P( 1, 3)).eq(new Sector(P(1, 3),P(2,+1),P(3,4),false,true));
    assert s.repoint(P( 0, 4)).eq(new Sector(P(0, 4),P(1,+2),P(1,6),false,true));
    assert s.repoint(P(-4,-1)).eq(new Sector(P(-4,-1),P(-7,-4),P(-2,0),true,false));

    assert !s.contains(P(-2,0));
    assert !s.contains(P(-2,1));
    assert  s.contains(P(-2,2));
    assert  s.contains(P(-2,3));
    assert  s.contains(P(-2,4));
    assert !s.contains(P(-2,5));
    assert !s.contains(P(0,0));
   }

  static void testSectors4()
   {final Sector s = new Sector(P(-1,+2),P(-3,+1), P(-2,+4), true, false);
    assert  s.contains(P(-2,0));
    assert  s.contains(P(-2,1));
    assert !s.contains(P(-2,2));
    assert !s.contains(P(-2,3));
    assert !s.contains(P(-2,4));
    assert  s.contains(P(-2,5));
    assert  s.contains(P(0,0));
   }

  static void testSectors5()
   {final Sector s = new Sector(P(1,1) ,P(-1,2) ,P(-1,1), false, true);
    final Sector t = s.repoint(P(1,3));
    assert  t.eq(new Sector(P(1,3), P(3,2), P(1,5), false, true));
   }

  static void testPoints()
   {assert  Point.close(P(3,4).len(), 5);
    assert  P(0,0).zero();
    assert  Point.le(1, 2);
    assert  Point.ge(2, 1);
    assert  Point.close(1,1);
    assert  Point.zero(P(1,0).add(P(0,1)).distance(P(1,1)));
    assert  P(1,0).add(P(0,1)).eq(P(1,1));
    assert  P(1,1).mul(2).eq(P(2,2));
    assert  P(2,2).div(2).eq(P(1,1));
    assert  P(2,2).normalize().eq(P(3,3).normalize());
    assert  P(2,2).col(P(3,3));
    assert  Point.close(P(1,0).cross(P(0,1)), 1);
    assert  Point.close(P(0,1).cross(P(1,0)), -1);
    assert  P(0,0).reflect(P(1,2)).eq(P(-1,-2));
    assert  P(0,0).schwartz(P(1,1), P(2,2));
    assert !P(0,0).schwartz(P(1,1), P(2,3));

    assert  P(1,0).cross(P(0,1)) ==  1;
    assert  P(0,1).cross(P(1,0)) == -1;
   }

  static void testLines()
   {testLines1();
    testLines2();
   }

  static void testLines1()
   {final Line l = L(P(2,2), P(4,6));
    assert  l.along(P(6, 10));
    assert !l.along(P(6, 11));

    final Line x = L(P(0,0), P(1,0));
    final Line y = L(P(0,0), P(0,1));
    assert x.side(P(0, 1)) == +1;
    assert y.side(P(1, 0)) == -1;

    assert  l.side(P(2,0)) == -1;
    assert  l.side(P(0,2)) ==  1;
   }

  static void testLines2()
   {final Line a = L(P(7,2),P(4,2)), b = L(P(4,3),P(6,1));
    final Point p = a.intersection(b);
    assert p.eq(P(5.0,2.0));
   }

  static void say(Object...O)
   {final StringBuilder b = new StringBuilder();
    for(Object o: O) {b.append(" "); b.append(o);}
    System.err.println((O.length > 0 ? b.substring(1) : ""));
   }

  static void stop(Object...O)
   {say(O);
    new Exception().printStackTrace();
    System.exit(0);
   }
 }

//TEST stripes
/*
 6  8 10 12
 4 14 15 11
 2 13 16  9
 1  3  5  7
----
14
*/

//TEST Square_and_Octagon
/*
  1  6  7  2
  5 13 14  8
 12 16 15  9
  4 11  10 3
----
9
*/

//TEST W
/*
 1  3  8  7
 4  2  6  9
13 12 15  5
16 14 10 11
----
14
*/

//TEST 3962
/*
16 15  5 14
13  6  2  1
 3  9 12  8
10  7  4 11
----
10
*/

//TEST zz notSure
/*
 1  3  5  8
 2  4  6  7
10 12 11  9
13 15 16 14
----
14
*/

//TEST 8741
/*
13  3  7  6
16  4 10 14
 1  9 11  2
 8 12 15  5
----
10
*/

//TEST 15a notSure
/*
 1  6  9 10
12  3  7  8
14 13  4  5
16 15 11  2
----
13
*/

//TEST aa
/*
  1  2  12  9
 11  3  16 13
  5  6  14  8
  4 15   7 10
----
10
*/

//TEST 58325
/*
  4 16 11 10
 15  1  9  5
 12  8  3  6
 14  7 13  2
----
9
*/

//TEST 1corner
/*
  1  2  3 16
 11 12 13  4
 10 15 14  5
  9  8  7  6
----
7
*/

//TEST 1corner5
/*
 13 14 15 16
 12 11  5  6
  1  2 10  7
  4  3  9  8
----
9
*/

//TEST iz
/*
  2 10 11  1
  8  9 12 13
  7 16 15 14
  6  5  4  3
----
10
*/

//TEST e3
/*
  2  1 15 12
  7  8  9  6
 14  4 16  3
  5 13 10 11
----
12
*/

//TEST Sq
/*
 16  5  6  7
 15  4  1  8
 14  3  2  9
 13 12 11 10
----
7
*/

//TEST M
/*
  10 2  5 11
  9 15 16 12
  8  6  1 13
  3  7 14  4
----
10
*/

//TEST a
/*
  1 16  7  8
  5  2  6  9
  4  3 15 10
 14 13 12 11
----
9
*/

//TEST ZigZag2
/*
 1 15 16  8
 7 9  14  2
 3 13 10  6
 5 11 12  4
----
15
*/

//TEST b
/*
  1  7   8  9
 16  2   3 10
 15  6   4 11
 14  5  13 12
----
8
*/

//TEST e3
/*
  2  1 15 12
  7  8  9  6
 14  4 16  3
  5 13 10 11
----
12
*/

//TEST Step
/*
 15 16  6  7
 14  4  5  8
  2  3  9 10
  1 13 12 11
----
12
*/

//TEST Octagon
/*
 9  2  3 16
 1 10 15  4
 8 14 11  5
 13 7  6 12
----
8
*/

//TEST Octagon2
/*
13  2  3 14
 1  9 10  4
 8 12 11  5
16  7  6 15
----
9
*/

//TEST ZigZag
/*
 1  2  3  4
16 12  5 13
15  6 11 14
 7  8  9 10
----
7
*/

//TEST Clover
/*
 3   2  7  6
 4  14 15  5
 11  1 16 10
 12 13  8  9
----
11
*/

//TEST Spiral
/*
14  2  3 15
 1  9 10  4
 8 12 11  5
13  7  6 16
----
10
*/

//TEST U3
/*
 11 10  7 13
  4  1  5  6
  3  8  9  2
 12 14 15 16
----
10
*/

//TEST U4
/*
 11  1  7 13
  4 10  5  6
  3  8  9  2
 12 14 15 16
----
10
*/

//TEST U5
/*
 11 13  7  1
  4 10  5  6
  3  8  9  2
 12 14 15 16
----
10
*/

//TEST uend
/*
  9 10  1 16
  8 11  2 15
  7 12  3 14
  6  5 13  4
----
8
*/

//TEST 12947
/*
  7 11  2  3
 10 13 16  4
  9  1 15  5
  8  6 14 12
----
9
*/

//TEST 15561
/*
 14 15  2  1
  5  6  7  8
  9  4 13 16
 10 11  3 12
----
9
*/

//TEST t12
/*
 3  5  7 16
 6 13  1 12
 4 14 15 10
 9 11  8  2
----
13
*/

//TEST xxx
/*
  6 12  7  8
 13  2 11  1
 14  9  5 15
  3  4 10 16
----
11
*/

//TEST e1

/*
  1 15  2 16
  7 11 14  3
 13 12  4 10
  5  6  8  9
----
12
*/

//TEST U2
/*
 12 13 10 11
  6  7  8  9
  5  4  3  2
 14 15  1 16
----
10
*/

//TEST 33811
/*
  5  6 12  3
  2 13  7  1
  8  9 11 10
 14 15  4 16
----
11
*/

//TEST U
/*
  4  3  1  2
  5 14 13 12
  6 16 15 11
  7  8 10  9
----
9
*/

//TEST t10
/*
  8  3 16 12
  2 13 11  4
  7  1 14  5
  6 10  9 15
----
10
*/

//TEST T11
/*
 16  3  4 10
  2 11 14  5
  9 15  1  6
 12  8  7 13
----
10
*/

//TEST 5191
/*
  7 13  3 16
  6 12  8  2
 14 11  1  4
 15 10  9  5
----
9
*/


//TEST 9839
/*
 13  9 16  5
  1  4  3  2
  8  6 15 10
  7 14 12 11
----
9
*/

//TEST loop2
/*
 1  2  3  4
 8 10 11 12
 9  7 14  5
16 15  6 13
----
10
*/

//TEST Corner
/*
 1  2  3  4
 8  9 10 11
 7 15 16 12
 6 14 13  5
----
7
*/

//TEST 1499
/*
  7 11 12  1
 10 13  8  2
 14  6  9  3
 15 16  5  4
----
8
*/

//TEST Cross
/*
 1  2  3  4
10 11 12  5
 9 16  6 13
 8  7 15 14
----
6
*/

//TEST 3
/*
 1  2  3  4
 5  6  7  8
12 11 10  9
13 14 15 16
----
7
*/

//TEST Spring
/*
 1  2  3  4
 5  6  7  8
 9 10 11 12
13 14 15 16
----
7
*/

//TEST zzz
/*
 1  3  4  2
 5  7  8  6
 9 11 12 10
13 15 16 14
----
15
*/

//TEST trigo
/*
 1  2  3  4
 9 10 11 12
 8 16 13  5
14  7  6 15
----
7
*/

//TEST squareSpiral
/*
 1  2  3  4
12 13 14  5
11 16 15  6
10  9  8  7
----
7
*/

//TEST squareSpiralOut
/*
16 15 14 13
 5  4  3 12
 6  1  2 11
 7  8  9 10
----
7
*/

//TEST loop
/*
 1  2  3  4
 9 10 11 12
 8  7  6  5
16 15 14 13
----
7
*/

//TEST star
/*
 1 14  9  3
 7 10  4 15
16  5 12  8
 6 11 13  2
----
12
*/

//TEST factory
/*
 1  3  5  7
 2  4  6  8
15 13 11  9
16 14 12 10
----
13
*/
