package de.japkit.model;

import de.japkit.model.GenAnnotatedConstruct;
import de.japkit.model.GenName;
import de.japkit.model.Property;
import de.japkit.rules.JavaBeansExtensions;
import de.japkit.services.ExtensionRegistry;
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

@Data
@SuppressWarnings("all")
public class PropertyImpl extends GenAnnotatedConstruct implements Property {
  /**
   * The type of the property.
   */
  private final TypeMirror type;
  
  /**
   * The name of the property.
   */
  private final String name;
  
  /**
   * The getter, if existent.
   */
  private final ExecutableElement getter;
  
  /**
   * The setter, if existent.
   */
  private final ExecutableElement setter;
  
  /**
   * The field, the property relates to, if existent.
   */
  private final VariableElement field;
  
  public PropertyImpl(final TypeMirror type, final String name, final ExecutableElement getter, final ExecutableElement setter, final VariableElement field) {
    this.type = type;
    this.name = name;
    this.getter = getter;
    this.setter = setter;
    this.field = field;
  }
  
  public PropertyImpl(final VariableElement field, final ExecutableElement getter, final ExecutableElement setter) {
    this(field.asType(), field.getSimpleName().toString(), getter, setter, field);
  }
  
  public PropertyImpl(final VariableElement field) {
    this(field.asType(), field.getSimpleName().toString(), null, null, field);
  }
  
  public PropertyImpl(final TypeMirror type, final String name) {
    this(type, name, null, null, null);
  }
  
  public PropertyImpl withSetter(final ExecutableElement setter) {
    return new PropertyImpl(this.type, this.name, this.getter, setter, this.field);
  }
  
  public PropertyImpl withGetter(final ExecutableElement getter) {
    return new PropertyImpl(this.type, this.name, getter, this.setter, this.field);
  }
  
  public PropertyImpl withField(final VariableElement field) {
    return new PropertyImpl(this.type, this.name, this.getter, this.setter, field);
  }
  
  @Override
  public <R extends Object, P extends Object> R accept(final ElementVisitor<R, P> v, final P p) {
    throw new UnsupportedOperationException("Not supported for class Property.");
  }
  
  @Override
  public TypeMirror asType() {
    return this.type;
  }
  
  @Override
  public <A extends Annotation> A getAnnotation(final Class<A> annotationType) {
    return this.fieldOrGetter().<A>getAnnotation(annotationType);
  }
  
  @Override
  public List<? extends AnnotationMirror> getAnnotationMirrors() {
    return this.fieldOrGetter().getAnnotationMirrors();
  }
  
  @Override
  public List<? extends Element> getEnclosedElements() {
    return this.fieldOrGetter().getEnclosedElements();
  }
  
  @Override
  public Element getEnclosingElement() {
    return this.fieldOrGetter().getEnclosingElement();
  }
  
  @Override
  public ElementKind getKind() {
    throw new UnsupportedOperationException("Not supported for class Property, since it is a derived element.");
  }
  
  @Override
  public Set<Modifier> getModifiers() {
    return this.fieldOrGetter().getModifiers();
  }
  
  @Override
  public Name getSimpleName() {
    return new GenName(this.name);
  }
  
  @Override
  public Element fieldOrGetter() {
    Element _xifexpression = null;
    if ((this.field != null)) {
      _xifexpression = this.field;
    } else {
      _xifexpression = this.getter;
    }
    return _xifexpression;
  }
  
  @Override
  public Object getConstantValue() {
    throw new UnsupportedOperationException("TODO: auto-generated method stub");
  }
  
  @Override
  public String toString() {
    return this.name.toString();
  }
  
  @Override
  public String getGetterName() {
    return ExtensionRegistry.<JavaBeansExtensions>get(JavaBeansExtensions.class).getterName(this);
  }
  
  @Override
  public String getSetterName() {
    return ExtensionRegistry.<JavaBeansExtensions>get(JavaBeansExtensions.class).setterName(this);
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = 1;
    result = prime * result + ((this.type== null) ? 0 : this.type.hashCode());
    result = prime * result + ((this.name== null) ? 0 : this.name.hashCode());
    result = prime * result + ((this.getter== null) ? 0 : this.getter.hashCode());
    result = prime * result + ((this.setter== null) ? 0 : this.setter.hashCode());
    return prime * result + ((this.field== null) ? 0 : this.field.hashCode());
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
    PropertyImpl other = (PropertyImpl) obj;
    if (this.type == null) {
      if (other.type != null)
        return false;
    } else if (!this.type.equals(other.type))
      return false;
    if (this.name == null) {
      if (other.name != null)
        return false;
    } else if (!this.name.equals(other.name))
      return false;
    if (this.getter == null) {
      if (other.getter != null)
        return false;
    } else if (!this.getter.equals(other.getter))
      return false;
    if (this.setter == null) {
      if (other.setter != null)
        return false;
    } else if (!this.setter.equals(other.setter))
      return false;
    if (this.field == null) {
      if (other.field != null)
        return false;
    } else if (!this.field.equals(other.field))
      return false;
    return true;
  }
  
  @Pure
  public TypeMirror getType() {
    return this.type;
  }
  
  @Pure
  public String getName() {
    return this.name;
  }
  
  @Pure
  public ExecutableElement getGetter() {
    return this.getter;
  }
  
  @Pure
  public ExecutableElement getSetter() {
    return this.setter;
  }
  
  @Pure
  public VariableElement getField() {
    return this.field;
  }
}
