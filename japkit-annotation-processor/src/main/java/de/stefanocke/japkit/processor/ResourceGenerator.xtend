package de.stefanocke.japkit.processor

import de.stefanocke.japkit.metaannotations.ResourceLocation
import de.stefanocke.japkit.metaannotations.ResourceTemplate
import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.GenerateClassContext
import de.stefanocke.japkit.support.MessageCollector
import de.stefanocke.japkit.support.NameRule
import de.stefanocke.japkit.support.ProcessingException
import de.stefanocke.japkit.support.TypeElementNotFoundException
import de.stefanocke.japkit.support.TypesRegistry
import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.support.el.ValueStack
import java.io.File
import java.io.FileOutputStream
import java.io.FileWriter
import java.io.IOException
import java.io.OutputStreamWriter
import java.nio.charset.Charset
import java.util.HashMap
import java.util.Map
import java.util.Set
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.tools.StandardLocation

class ResourceGenerator {

	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension ProcessingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val ELSupport elSupport = ExtensionRegistry.get(ELSupport)

	//The directory for resource templates if they are kept locally within the project.
	//We need this, since Java Annotation Processing has very limited options from where to load source files. 
	def private getResourceTemplateDir() {
		options.get("templateDir")
	}

	def processResourceTemplatesAnnotation(TypeElement annotatedClass, AnnotationMirror triggerAnnotation) {
		val resourceTemplateAnnotations = triggerAnnotation.metaAnnotations(ResourceTemplate)
		if(resourceTemplateAnnotations.empty) return;

		resourceTemplateAnnotations.forEach [ resourceTemplateAnnotation |
			
			//TODO: Caching as Rule
			val templateName = resourceTemplateAnnotation.value("templateName", String);
			val templateLang = resourceTemplateAnnotation.value("templateLang", String);		
			val templatePackagePath = triggerAnnotation.annotationAsTypeElement.package.qualifiedName.toString.replace('.', '/')
			
			
			val resoureNameRule = new NameRule(triggerAnnotation, resourceTemplateAnnotation, "name")
			val resourePathNameRule = new NameRule(triggerAnnotation, resourceTemplateAnnotation, "path")
			
			val resourceLocation = resourceTemplateAnnotation.value("location", ResourceLocation);	
			
			try {
				pushCurrentMetaAnnotation(resourceTemplateAnnotation)
				
				elSupport.putELVariables(annotatedClass, triggerAnnotation, resourceTemplateAnnotation)
				
				var Long templateLastModified = null
				
				val templateURL = if (resourceTemplateDir != null) {
						val templateDir = new File(resourceTemplateDir, templatePackagePath)
						val file = new File(templateDir, templateName)
						templateLastModified=file.lastModified
						file.toURI.toURL
					} else {
						class.classLoader.getResource(templatePackagePath+'/'+templateName)					
					}

				// filer.getResource(StandardLocation.CLASS_OUTPUT, triggerAnnotation.annotationAsTypeElement.package.qualifiedName, templateName).toUri;
				printDiagnosticMessage['''Resoure template «templateName» «templateURL»''']

				val resourceName = resoureNameRule.getName(templateName, annotatedClass)
				val resourcePathName = resourePathNameRule.getName(annotatedClass.package.qualifiedName.toString.replace('.', '/'), annotatedClass)
					
				val resourceFile = resourceLocation.getFile(options, resourcePathName, resourceName)
				resourceFile.ensureParentDirectoriesExist			
				val writer = new FileWriter(resourceFile)
				//new OutputStreamWriter(new FileOutputStream(resourceFile), "UTF-8")
				
				val start = System.currentTimeMillis
				try {
					
					elSupport.write(writer, templateURL, templateLang, templateLastModified)

				} finally {
					writer.flush
					writer.close
					printDiagnosticMessage['''Resource file written «resourceFile». Duration: «System.currentTimeMillis - start»''']
				}
			} catch (TypeElementNotFoundException tenfe) { 
				handleTypeElementNotFound(
					'''Type element not found when processing resource template «templateName» for «annotatedClass».''',
					tenfe.fqn, annotatedClass)
			} catch (Exception e) {
				printDiagnosticMessage['''Error when processing resource template «templateName» for «annotatedClass». «e»''']
				reportError('''Error when processing resource template  «templateName».''', e, annotatedClass, triggerAnnotation, null)
			} finally {
				popCurrentMetaAnnotation
			}
		]

	}
	
	val Set<File> existingDirs = newHashSet
	
	def private void ensureParentDirectoriesExist(File f) throws IOException {     
            val parent = f.getParentFile();
            
            if(existingDirs.contains(parent)) return;
            
            if (parent != null && !parent.exists()) {
                if (!parent.mkdirs()) {
                    // could have been concurrently created
                    if (!parent.exists() || !parent.isDirectory())
                        throw new IOException("Unable to create parent directories for " + f); //$NON-NLS-1$
                }
                existingDirs.add(parent)
            }
            
    }
        
    

}
