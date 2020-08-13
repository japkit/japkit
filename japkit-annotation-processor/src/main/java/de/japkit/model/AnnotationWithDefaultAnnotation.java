package de.japkit.model;

import java.util.HashMap;
import java.util.Map;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.type.DeclaredType;

import org.eclipse.xtend.lib.annotations.Data;
import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

@Data
@SuppressWarnings("all")
public class AnnotationWithDefaultAnnotation implements AnnotationMirror {
  private final AnnotationMirror annotation;
  
  private final AnnotationMirror defaultAnnotation;
  
  @Override
  public DeclaredType getAnnotationType() {
    return this.annotation.getAnnotationType();
  }
  
  @Override
  public Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValues() {
    HashMap<ExecutableElement, AnnotationValue> _xblockexpression = null;
    {
      Map<? extends ExecutableElement, ? extends AnnotationValue> _elementValues = this.defaultAnnotation.getElementValues();
      final HashMap<ExecutableElement, AnnotationValue> result = new HashMap<ExecutableElement, AnnotationValue>(_elementValues);
      result.putAll(this.annotation.getElementValues());
      _xblockexpression = result;
    }
    return _xblockexpression;
  }
  
  public static AnnotationMirror createIfNecessary(final AnnotationMirror annotation, final AnnotationMirror defaultAnnotation) {
    AnnotationMirror _xifexpression = null;
    if (((annotation != null) && (defaultAnnotation != null))) {
      _xifexpression = new AnnotationWithDefaultAnnotation(annotation, defaultAnnotation);
    } else {
      AnnotationMirror _elvis = null;
      if (annotation != null) {
        _elvis = annotation;
      } else {
        _elvis = defaultAnnotation;
      }
      _xifexpression = _elvis;
    }
    return _xifexpression;
  }
  
  public AnnotationWithDefaultAnnotation(final AnnotationMirror annotation, final AnnotationMirror defaultAnnotation) {
    super();
    this.annotation = annotation;
    this.defaultAnnotation = defaultAnnotation;
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = 1;
    result = prime * result + ((this.annotation== null) ? 0 : this.annotation.hashCode());
    return prime * result + ((this.defaultAnnotation== null) ? 0 : this.defaultAnnotation.hashCode());
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
    AnnotationWithDefaultAnnotation other = (AnnotationWithDefaultAnnotation) obj;
    if (this.annotation == null) {
      if (other.annotation != null)
        return false;
    } else if (!this.annotation.equals(other.annotation))
      return false;
    if (this.defaultAnnotation == null) {
      if (other.defaultAnnotation != null)
        return false;
    } else if (!this.defaultAnnotation.equals(other.defaultAnnotation))
      return false;
    return true;
  }
  
  @Override
  @Pure
  public String toString() {
    ToStringBuilder b = new ToStringBuilder(this);
    b.add("annotation", this.annotation);
    b.add("defaultAnnotation", this.defaultAnnotation);
    return b.toString();
  }
  
  @Pure
  public AnnotationMirror getAnnotation() {
    return this.annotation;
  }
  
  @Pure
  public AnnotationMirror getDefaultAnnotation() {
    return this.defaultAnnotation;
  }
}
