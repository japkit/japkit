package de.japkit.model;

import java.lang.annotation.Annotation;
import java.util.List;
import java.util.Set;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ElementVisitor;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.element.Modifier;
import javax.lang.model.element.Name;
import javax.lang.model.element.VariableElement;
import javax.lang.model.type.TypeMirror;

import org.eclipse.xtend.lib.annotations.Data;
import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

@Data
@SuppressWarnings("all")
public class ParameterWrapper extends GenAnnotatedConstruct implements VariableElement {
  private final ExecutableElement enclosing;
  
  private final int index;
  
  private final VariableElement delegate;
  
  private final Name name;
  
  @Override
  public Object getConstantValue() {
    return this.delegate.getConstantValue();
  }
  
  @Override
  public <R extends Object, P extends Object> R accept(final ElementVisitor<R, P> v, final P p) {
    throw new UnsupportedOperationException("TODO: auto-generated method stub");
  }
  
  @Override
  public TypeMirror asType() {
    return this.delegate.asType();
  }
  
  @Override
  public <A extends Annotation> A getAnnotation(final Class<A> annotationType) {
    return this.delegate.<A>getAnnotation(annotationType);
  }
  
  @Override
  public List<? extends AnnotationMirror> getAnnotationMirrors() {
    return this.delegate.getAnnotationMirrors();
  }
  
  @Override
  public List<? extends Element> getEnclosedElements() {
    return this.delegate.getEnclosedElements();
  }
  
  @Override
  public Element getEnclosingElement() {
    return this.enclosing;
  }
  
  @Override
  public ElementKind getKind() {
    return this.delegate.getKind();
  }
  
  @Override
  public Set<Modifier> getModifiers() {
    return this.delegate.getModifiers();
  }
  
  @Override
  public Name getSimpleName() {
    Name _xifexpression = null;
    if ((this.name != null)) {
      _xifexpression = this.name;
    } else {
      _xifexpression = this.delegate.getSimpleName();
    }
    return _xifexpression;
  }
  
  public ParameterWrapper(final ExecutableElement enclosing, final int index, final VariableElement delegate, final Name name) {
    super();
    this.enclosing = enclosing;
    this.index = index;
    this.delegate = delegate;
    this.name = name;
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = 1;
    result = prime * result + ((this.enclosing== null) ? 0 : this.enclosing.hashCode());
    result = prime * result + this.index;
    result = prime * result + ((this.delegate== null) ? 0 : this.delegate.hashCode());
    return prime * result + ((this.name== null) ? 0 : this.name.hashCode());
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
    ParameterWrapper other = (ParameterWrapper) obj;
    if (this.enclosing == null) {
      if (other.enclosing != null)
        return false;
    } else if (!this.enclosing.equals(other.enclosing))
      return false;
    if (other.index != this.index)
      return false;
    if (this.delegate == null) {
      if (other.delegate != null)
        return false;
    } else if (!this.delegate.equals(other.delegate))
      return false;
    if (this.name == null) {
      if (other.name != null)
        return false;
    } else if (!this.name.equals(other.name))
      return false;
    return true;
  }
  
  @Override
  @Pure
  public String toString() {
    return new ToStringBuilder(this)
    	.addAllFields()
    	.toString();
  }
  
  @Pure
  public ExecutableElement getEnclosing() {
    return this.enclosing;
  }
  
  @Pure
  public int getIndex() {
    return this.index;
  }
  
  @Pure
  public VariableElement getDelegate() {
    return this.delegate;
  }
  
  @Pure
  public Name getName() {
    return this.name;
  }
}
