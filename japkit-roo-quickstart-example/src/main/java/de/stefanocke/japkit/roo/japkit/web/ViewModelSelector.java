package de.stefanocke.japkit.roo.japkit.web;

import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;

@ClassSelector(expr = "#{viewModel != null ? viewModel : fbo  }")
public abstract class ViewModelSelector {
}