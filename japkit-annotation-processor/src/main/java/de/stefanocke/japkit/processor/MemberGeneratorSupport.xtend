package de.stefanocke.japkit.processor

import de.stefanocke.japkit.support.AnnotationExtensions
import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.GenerateClassContext
import de.stefanocke.japkit.support.JavaBeansExtensions
import de.stefanocke.japkit.support.MessageCollector
import de.stefanocke.japkit.support.RelatedTypes
import de.stefanocke.japkit.support.TypesExtensions
import de.stefanocke.japkit.support.TypesRegistry
import javax.annotation.processing.ProcessingEnvironment
import de.stefanocke.japkit.support.RuleFactory

abstract class MemberGeneratorSupport implements MemberGenerator {
	protected extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	protected extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	protected extension ElementsExtensions  = ExtensionRegistry.get(ElementsExtensions)
	protected extension AnnotationExtensions annotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
	protected extension JavaBeansExtensions javaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	protected extension ProcessingEnvironment processingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	protected extension RelatedTypes relatedTypes = ExtensionRegistry.get(RelatedTypes)
	protected extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	protected extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	protected extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	
	
}