package de.japkit.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.Element;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.type.DeclaredType;

import org.eclipse.xtend.lib.annotations.Data;
import org.eclipse.xtext.xbase.lib.Pure;

@Data
@SuppressWarnings("all")
public class AnnotationAndParent implements AnnotationWrapper {
	private final AnnotationMirror annotation;

	private final Path.Segment pathSegment;

	private final AnnotationAndParent parentAnnotation;

	private final Element annotatedElement;

	@Override
	public DeclaredType getAnnotationType() {
		return this.annotation.getAnnotationType();
	}

	@Override
	public Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValues() {
		return this.annotation.getElementValues();
	}

	public Element getRootAnnotatedElement() {
		Element _elvis = null;
		Element _rootAnnotatedElement = null;
		if (this.parentAnnotation != null) {
			_rootAnnotatedElement = this.parentAnnotation.getRootAnnotatedElement();
		}
		if (_rootAnnotatedElement != null) {
			_elvis = _rootAnnotatedElement;
		} else {
			_elvis = this.annotatedElement;
		}
		return _elvis;
	}

	public AnnotationMirror getRootAnnotation() {
		AnnotationMirror _elvis = null;
		AnnotationMirror _rootAnnotation = null;
		if (this.parentAnnotation != null) {
			_rootAnnotation = this.parentAnnotation.getRootAnnotation();
		}
		if (_rootAnnotation != null) {
			_elvis = _rootAnnotation;
		} else {
			_elvis = this.annotation;
		}
		return _elvis;
	}

	public Path getPathFromRootAnnotation() {
		List<Path.Segment> _pathFromRootAnnotation_ = this.getPathFromRootAnnotation_();
		return new Path(_pathFromRootAnnotation_);
	}

	private List<Path.Segment> getPathFromRootAnnotation_() {
		List<Path.Segment> _xifexpression = null;
		if ((this.parentAnnotation == null)) {
			_xifexpression = new ArrayList<>();
		} else {
			List<Path.Segment> _xblockexpression = null;
			{
				final List<Path.Segment> path = this.parentAnnotation.getPathFromRootAnnotation_();
				path.add(this.pathSegment);
				_xblockexpression = path;
			}
			_xifexpression = _xblockexpression;
		}
		return _xifexpression;
	}

	@Override
	public String toString() {
		String _string = null;
		if (this.annotation != null) {
			_string = this.annotation.toString();
		}
		return _string;
	}

	public AnnotationAndParent(final AnnotationMirror annotation, final Path.Segment pathSegment,
			final AnnotationAndParent parentAnnotation, final Element annotatedElement) {
		super();
		this.annotation = annotation;
		this.pathSegment = pathSegment;
		this.parentAnnotation = parentAnnotation;
		this.annotatedElement = annotatedElement;
	}

	@Override
	@Pure
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((this.annotation == null) ? 0 : this.annotation.hashCode());
		result = prime * result + ((this.pathSegment == null) ? 0 : this.pathSegment.hashCode());
		result = prime * result + ((this.parentAnnotation == null) ? 0 : this.parentAnnotation.hashCode());
		return prime * result + ((this.annotatedElement == null) ? 0 : this.annotatedElement.hashCode());
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
		AnnotationAndParent other = (AnnotationAndParent) obj;
		if (this.annotation == null) {
			if (other.annotation != null)
				return false;
		} else if (!this.annotation.equals(other.annotation))
			return false;
		if (this.pathSegment == null) {
			if (other.pathSegment != null)
				return false;
		} else if (!this.pathSegment.equals(other.pathSegment))
			return false;
		if (this.parentAnnotation == null) {
			if (other.parentAnnotation != null)
				return false;
		} else if (!this.parentAnnotation.equals(other.parentAnnotation))
			return false;
		if (this.annotatedElement == null) {
			if (other.annotatedElement != null)
				return false;
		} else if (!this.annotatedElement.equals(other.annotatedElement))
			return false;
		return true;
	}

	@Override
	@Pure
	public AnnotationMirror getAnnotation() {
		return this.annotation;
	}

	@Pure
	public Path.Segment getPathSegment() {
		return this.pathSegment;
	}

	@Pure
	public AnnotationAndParent getParentAnnotation() {
		return this.parentAnnotation;
	}

	@Pure
	public Element getAnnotatedElement() {
		return this.annotatedElement;
	}
}
