package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ElVariableError
import de.stefanocke.japkit.metaannotations.ResourceLocation
import de.stefanocke.japkit.services.ExtensionRegistry
import de.stefanocke.japkit.services.FileExtensions
import de.stefanocke.japkit.services.TypeElementNotFoundException
import java.io.File
import java.io.FileWriter
import java.net.URL
import java.util.List
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.PackageElement
import org.eclipse.xtend.lib.annotations.Data

@Data
class ResourceRule extends AbstractRule{

	val transient extension ProcessingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	val transient extension FileExtensions = ExtensionRegistry.get(FileExtensions)
	
	
	String templateName
	String templateLang
	
	((Object)=>Object)=>List<Object> scopeRule
	
	NameRule resoureNameRule
	NameRule resourePathNameRule
	ResourceLocation resourceLocation
	
	URL templateURL
	Long templateLastModified 

	new(AnnotationMirror resourceTemplateAnnotation, PackageElement templatePackage){
		super(resourceTemplateAnnotation, null)
		
		templateName = resourceTemplateAnnotation.value("templateName", String);
		templateLang = resourceTemplateAnnotation.value("templateLang", String);	
		
		resoureNameRule = new NameRule(resourceTemplateAnnotation, "name")
		resourePathNameRule = new NameRule(resourceTemplateAnnotation, "path")
			
		resourceLocation = resourceTemplateAnnotation.value("location", ResourceLocation);
			
		scopeRule = createScopeRule(resourceTemplateAnnotation, null, null)
		
		
		val templatePackagePath = templatePackage.qualifiedName.toString.replace('.', '/')
				
		var Long lastModified=null	
		templateURL = if (resourceTemplateDir != null) {
			val templateDir = new File(resourceTemplateDir, templatePackagePath)
			val file = new File(templateDir, templateName)
			lastModified=file.lastModified
			file.toURI.toURL
		} else {
			
			//Note: This requires the templates to be in the classpath of the annotation processor
			class.classLoader.getResource(templatePackagePath+'/'+templateName)						
		}
		templateLastModified = lastModified
		
	}
	
	

	//The directory for resource templates if they are kept locally within the project.
	//We need this, since Java Annotation Processing has very limited options from where to load source files. 
	def private getResourceTemplateDir() {
		options.get("templateDir")
	}

	def void generateResource() {		
			
		inRule[	
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
						
						write(writer, templateURL, templateLang, templateLastModified)
	
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
			} catch(ElVariableError e){
				printDiagnosticMessage[e.message]
				//no error here, since it was already reported by the EL var rule
			} 
			catch (Exception e) {
				printDiagnosticMessage['''Error when processing resource template «templateName». «e»''']
				reportRuleError('''Error when processing resource template  «templateName»: «e»''')
			} 
			null
		]

	}
	       
    

}
