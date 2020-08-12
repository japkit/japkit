package de.japkit.model;

import java.util.Map;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.PackageElement;

import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Functions.Function1;

import de.japkit.util.MoreCollectionExtensions;

public class GenPackage extends GenElement implements PackageElement {
	private static final String simpleName_default = null;

	private Name qualifiedName;

	private boolean unnamed;

	private static final Map<CharSequence, GenPackage> packageForName = CollectionLiterals.newHashMap();

	public GenPackage(final CharSequence qualifiedName) {
		super();
		String _string = qualifiedName.toString();
		GenName _genName = new GenName(_string);
		this.setQualifiedName(_genName);
	}

	public static GenPackage packageForName(final CharSequence qualifiedName) {
		final Function1<CharSequence, GenPackage> _function = (CharSequence it) -> {
			return new GenPackage(qualifiedName);
		};
		return MoreCollectionExtensions.getOrCreate(GenPackage.packageForName, qualifiedName, _function);
	}

	@Override
	public Name getQualifiedName() {
		return qualifiedName;
	}

	public void setQualifiedName(final Name qualifiedName) {
		this.qualifiedName = qualifiedName;
	}

	@Override
	public boolean isUnnamed() {
		return unnamed;
	}

	public void setUnnamed(final boolean unnamed) {
		this.unnamed = unnamed;
	}

	@Override
	public ElementKind getKind() {
		return ElementKind.PACKAGE;
	}

	public GenPackage(final Name qualifiedName) {
		super();
		this.qualifiedName = qualifiedName;
	}
}
