package de.stefanocke.japkit.support

import de.stefanocke.japkit.metaannotations.ResourceLocation
import de.stefanocke.japkit.support.el.ELSupport
import java.io.File
import java.io.FileWriter
import java.io.IOException
import java.util.List
import java.util.Set
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import java.net.URL
import javax.lang.model.element.PackageElement

@Data
class ResourceRule {
	
	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension ProcessingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val extension RuleUtils ru = ExtensionRegistry.get(RuleUtils)
	val ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val extension FileExtensions = ExtensionRegistry.get(FileExtensions)
	
	AnnotationMirror resourceTemplateAnnotation
	String templateName
	String templateLang
	
	((Object)=>Object)=>List<Object> scopeRule
	
	NameRule resoureNameRule
	NameRule resourePathNameRule
	ResourceLocation resourceLocation
	
	URL templateURL
	Long templateLastModified 

	new(AnnotationMirror resourceTemplateAnnotation, PackageElement templatePackage){
		_resourceTemplateAnnotation = resourceTemplateAnnotation
		_templateName = resourceTemplateAnnotation.value("templateName", String);
		_templateLang = resourceTemplateAnnotation.value("templateLang", String);	
		
		_resoureNameRule = new NameRule(resourceTemplateAnnotation, "name")
		_resourePathNameRule = new NameRule(resourceTemplateAnnotation, "path")
			
		_resourceLocation = resourceTemplateAnnotation.value("location", ResourceLocation);
			
		_scopeRule = createScopeRule(resourceTemplateAnnotation, null)
		
		
		val templatePackagePath = templatePackage.qualifiedName.toString.replace('.', '/')
				
		var Long lastModified=null	
		_templateURL = if (resourceTemplateDir != null) {
			val templateDir = new File(resourceTemplateDir, templatePackagePath)
			val file = new File(templateDir, templateName)
			lastModified=file.lastModified
			file.toURI.toURL
		} else {
			
			//Note: This requires the templates to be in the classpath of the annotation processor
			class.classLoader.getResource(templatePackagePath+'/'+templateName)						
		}
		_templateLastModified = lastModified
		
	}
	
	

	//The directory for resource templates if they are kept locally within the project.
	//We need this, since Java Annotation Processing has very limited options from where to load source files. 
	def private getResourceTemplateDir() {
		options.get("templateDir")
	}

	def generateResource() {		
			
			pushCurrentMetaAnnotation(resourceTemplateAnnotation)
			try {
								
				scopeRule.apply [
				
					
					// filer.getResource(StandardLocation.CLASS_OUTPUT, triggerAnnotation.annotationAsTypeElement.package.qualifiedName, templateName).toUri;
					printDiagnosticMessage['''Resoure template «templateName» «templateURL»''']
	
					val resourceName = resoureNameRule.getName(templateName, currentAnnotatedClass)
					val resourcePathName = resourePathNameRule.getName(currentAnnotatedClass.package.qualifiedName.toString.replace('.', '/'), currentAnnotatedClass)
						
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
					null
				]
			} catch (TypeElementNotFoundException tenfe) { 
				handleTypeElementNotFound(
					'''Type element not found when processing resource template «templateName».''',	tenfe.fqn)
			} catch (Exception e) {
				printDiagnosticMessage['''Error when processing resource template «templateName». «e»''']
				reportError('''Error when processing resource template  «templateName».''', e, null, null, null)
			} finally {
				popCurrentMetaAnnotation
			}
		

	}
	       
    

}