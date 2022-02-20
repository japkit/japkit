package de.japkit.model;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.xtend.lib.annotations.Data;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.ListExtensions;
import org.eclipse.xtext.xbase.lib.Pure;

/**
 * Path for nested annotations / annotation values or for bean properties.
 */
@Data
@SuppressWarnings("all")
public class Path {
  @Data
  public static class Segment {
    private final String name;
    
    private final Integer index;
    
    @Override
    public String toString() {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append(this.name);
      {
        if ((this.index != null)) {
          _builder.append("[");
          _builder.append(this.index);
          _builder.append("]");
        }
      }
      return _builder.toString();
    }
    
    public Segment(final String name, final Integer index) {
      super();
      this.name = name;
      this.index = index;
    }
    
    @Override
    @Pure
    public int hashCode() {
      final int prime = 31;
      int result = 1;
      result = prime * result + ((this.name== null) ? 0 : this.name.hashCode());
      return prime * result + ((this.index== null) ? 0 : this.index.hashCode());
    }
    
    @Override
    @Pure
    public boolean equals(final Object obj) {
      if (this == obj)
        return true;
      if (obj == null)
        return false;
      if (getClass() != obj.getClass())
        return false;
      Path.Segment other = (Path.Segment) obj;
      if (this.name == null) {
        if (other.name != null)
          return false;
      } else if (!this.name.equals(other.name))
        return false;
      if (this.index == null) {
        if (other.index != null)
          return false;
      } else if (!this.index.equals(other.index))
        return false;
      return true;
    }
    
    @Pure
    public String getName() {
      return this.name;
    }
    
    @Pure
    public Integer getIndex() {
      return this.index;
    }
  }
  
  private final List<Path.Segment> segments;
  
  @Override
  public String toString() {
    final Function1<Path.Segment, String> _function = (Path.Segment it) -> {
      return it.toString();
    };
    return IterableExtensions.join(ListExtensions.<Path.Segment, String>map(this.segments, _function), ".");
  }
  
  public Path append(final Path.Segment segment) {
    Path _xblockexpression = null;
    {
      final ArrayList<Path.Segment> newSegments = new ArrayList<Path.Segment>(this.segments);
      newSegments.add(segment);
      _xblockexpression = new Path(newSegments);
    }
    return _xblockexpression;
  }
  
  public Path(final List<Path.Segment> segments) {
    super();
    this.segments = segments;
  }
  
  @Override
  @Pure
  public int hashCode() {
    return 31 * 1 + ((this.segments== null) ? 0 : this.segments.hashCode());
  }
  
  @Override
  @Pure
  public boolean equals(final Object obj) {
    if (this == obj)
      return true;
    if (obj == null)
      return false;
    if (getClass() != obj.getClass())
      return false;
    Path other = (Path) obj;
    if (this.segments == null) {
      if (other.segments != null)
        return false;
    } else if (!this.segments.equals(other.segments))
      return false;
    return true;
  }
  
  @Pure
  public List<Path.Segment> getSegments() {
    return this.segments;
  }
}
