package de.japkit.model;

import com.google.common.base.Objects;
import javax.lang.model.element.Name;
import org.eclipse.xtend.lib.annotations.Data;
import org.eclipse.xtext.xbase.lib.Pure;

@Data
@SuppressWarnings("all")
public class GenName implements Name {
  private final String name;
  
  @Override
  public boolean contentEquals(final CharSequence cs) {
    String _string = cs.toString();
    return Objects.equal(this.name, _string);
  }
  
  @Override
  public char charAt(final int index) {
    return this.name.charAt(index);
  }
  
  @Override
  public int length() {
    return this.name.length();
  }
  
  @Override
  public CharSequence subSequence(final int start, final int end) {
    return this.name.subSequence(start, end);
  }
  
  @Override
  public String toString() {
    return this.name;
  }
  
  public GenName(final String name) {
    super();
    this.name = name;
  }
  
  @Override
  @Pure
  public int hashCode() {
    return 31 * 1 + ((this.name== null) ? 0 : this.name.hashCode());
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
    GenName other = (GenName) obj;
    if (this.name == null) {
      if (other.name != null)
        return false;
    } else if (!this.name.equals(other.name))
      return false;
    return true;
  }
  
  @Pure
  public String getName() {
    return this.name;
  }
}
