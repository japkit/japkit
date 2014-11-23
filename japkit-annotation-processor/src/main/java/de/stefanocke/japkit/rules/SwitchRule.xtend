package de.stefanocke.japkit.rules

import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import org.eclipse.xtend.lib.annotations.Data

@Data
class SwitchRule extends AbstractRule{
	
	
	List<Pair<ElementMatcher, String>> cases
	
	def String caseName(Element e){
		inRule[
			val theCase = cases.findFirst[
				key == null || key.matches(e)
			]
			if(theCase == null){
				throw new IllegalArgumentException('''The switcher could not match element «e».''')
			}
			theCase.value
		
		]
	}
	
	new(AnnotationMirror switchAm){
		super(switchAm, null)
		cases = switchAm.value("value", typeof(AnnotationMirror[])).map[ caseAm |
			{
				val matcherAm = caseAm.value("matcher", AnnotationMirror)
				matcherAm?.createElementMatcher() 			
			}
			-> caseAm.value("name", String)
		]
	}
	
	//Bessere Idee: Switcher ist Klasse mit Inner classes. An den stehen dann jeweils die Matcher. Vorteil: Die Cases können
	//in anderen Annotationen "typsicher" referenziert werden. In resource templates kann ggf der simple name verwendet werden. 
}