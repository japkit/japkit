package de.japkit.rules

import de.japkit.el.ELSupport
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import java.util.regex.Pattern
import javax.lang.model.element.AnnotationMirror
import org.eclipse.xtend.lib.annotations.Data
import de.japkit.rules.RuleException

/**
 * A NameRule describes how to derive the name of the target element from the source element.
 * This rule is only used at the "top-level", that is, for the generated classes and resources.
 * For members etc, the nameExprRule from RuleUtils is used instead.
 * (TODO: can this be harmonized without breaking something?)
 * 
 * The rule supports:
 * <ul>
 * <li>creating the name by RegEx replacement of the source name
 * <li>creating the name by evaluating an expression
 * </ul>
 */
@Data
class NameRule extends AbstractRule {
	Pattern regEx
	String regExReplace
	String expr
	String lang
	String prefix

	val transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient extension ELSupport = ExtensionRegistry.get(ELSupport)

	new(AnnotationMirror metaAnnotation, String avPrefix) {
		super(metaAnnotation, null)
		prefix = if(avPrefix === null) "name" else avPrefix
		regEx = metaAnnotation.value('''«prefix»RegEx''', Pattern)
		regExReplace = metaAnnotation.value('''«prefix»RegExReplace''', String)
		expr = metaAnnotation.value('''«prefix»Expr''', String)
		lang = metaAnnotation.value('''«prefix»Lang''', String)
	}

	def isEmpty() {
		regEx === null && expr === null
	}

	def String getName(CharSequence orgName) {
		inRule[
			if (regEx !== null) {

				val matcher = regEx.matcher(orgName)

				if (!matcher.matches) {
					throw new RuleException('''Naming rule violated: Name "«orgName»" must match pattern "«regEx.pattern»"''', '''«prefix»RegEx''')
				}
				try {
					val name = matcher.replaceFirst(regExReplace)
					if (name.empty) {
						throw new RuleException('''Naming rule violated: Name "«orgName»" must not be empty after replacing with "«regExReplace»"''', '''«prefix»RegExReplace''')
					}
					return name
				} catch (RuntimeException e) {
					throw new RuleException('''Exception when replacing RegEx "«regEx.pattern»" with "«regExReplace»": «e.message»''', '''«prefix»RegEx''')
				}

			} else if (!expr.nullOrEmpty) {
				handleException(null, '''«prefix»Expr''') [
					eval(expr, lang, String)
				]
			} else {
				orgName.toString
			}
		]
	}
}
