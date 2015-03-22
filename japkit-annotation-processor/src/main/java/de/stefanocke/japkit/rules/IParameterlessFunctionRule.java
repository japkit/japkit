package de.stefanocke.japkit.rules;

import org.eclipse.xtext.xbase.lib.Functions.Function0;
import org.eclipse.xtext.xbase.lib.Functions.Function1;

/**
 * Interface for all functions than can be called with no parameters and alternatively with one parameter which is the "src".
 * @author stefan
 *
 * @param <T>
 */
public interface IParameterlessFunctionRule<T> extends Function1<Object, T>,  Function0<T>, Rule {

}
