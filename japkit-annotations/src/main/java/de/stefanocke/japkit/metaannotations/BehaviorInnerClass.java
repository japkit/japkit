package de.stefanocke.japkit.metaannotations;

import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;

@ClassSelector(kind=ClassSelectorKind.INNER_CLASS_NAME, avName="behaviorInnerClassName", expr="Behavior")
public interface BehaviorInnerClass{}