package de.japkit.activeannotations

import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.HashSet
import java.util.List
import java.util.Set
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationTarget
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.ConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.PrimitiveType
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility

class FieldsFromInterfaceProcessor extends AbstractClassProcessor {
	extension TransformationContext context

	val COLLECTION_IMPL = #{
		List.name -> ArrayList.name,
		Set.name -> HashSet.name,
		Collection.name -> ArrayList.name
	}

	
	
	override void doTransform(MutableClassDeclaration annotatedClass,  extension TransformationContext context
		
	) {
		
		
		try{
		this.context = context
		val interfaces = annotatedClass.implementedInterfaces
		if (interfaces.size != 1) {
			annotatedClass.addError("The class must implement exactly one interface.")
			return
		}
		val interfaceDecl = interfaces.head.type as InterfaceDeclaration

		interfaceDecl.allMethods.filter[m|m.isGetter].forEach [ m |
			val property = m.propertyName
			val propertyType = m.returnType
			val existingGetter = annotatedClass.findMostSpecificMethod(m)
			val existingField = annotatedClass.findDeclaredField(property)
			
			//Determines if the interfaces of the superclass already contain getter (and so, this processor will generate a getter in a superclass at later point in time)
			//val existingGetterInSuperClassInterfaces = annotatedClass.superClass?.findMethodInInterfaces(m)			
			
			//addWarning(annotatedClass, '''property: «property» ; superclass «annotatedClass.superClass?.qualifiedName»; superclass interfaces: «annotatedClass.superClass?.interfaces.map[simpleName]» ;  existing getter in superinterfaces: «existingGetterInSuperClassInterfaces?.declaringType?.qualifiedName»''')
			
			val generateField = shallGenerateField(annotatedClass, existingField, existingGetter)
			
			if (generateField) {
				annotatedClass.addField(property) [
					if (!propertyType.isCollection) {
						it.type = propertyType
					} else {
						val elementType = propertyType.actualTypeArguments.head.upperBound //???	
						it.type = newTypeReference(propertyType.type, elementType);
						val implType = context.newTypeReference(COLLECTION_IMPL.get(propertyType.type.qualifiedName),
							elementType);
						it.initializer = ['''new «implType.name»()''']
					}
				//TODO: Default value support
				]
			}
			//generate accessors if there is a field (generated or existing)
			if (generateField || existingField !== null) {
				if (shallGenerateGetter(annotatedClass, existingField, existingGetter)) {
					annotatedClass.addMethod(m.simpleName) [
						it.returnType = propertyType
						if(!propertyType.isCollection){
							body = ['''return «property»;''']
						} else {
							body = ['''return java.util.Collections.unmodifiable«propertyType.type.simpleName»(«property»);''']
						}
						
					]
				}

				if (!propertyType.isCollection) {
					val existingSetter = annotatedClass.findMostSpecificMethod(property.setterName, propertyType)
					if (shallGenerateSetter(annotatedClass, existingField, existingSetter)) {

						annotatedClass.addMethod(property.setterName) [
							addParameter(property, propertyType)
							visibility = if(existingSetter !== null) existingSetter.visibility else Visibility.PUBLIC
							body = ['''this.«property» = «property»;''']
						]

					}
				} else {
					
					val elementType = propertyType.actualTypeArguments.head.upperBound
					
					val existingAdder = annotatedClass.findMostSpecificMethod(property.adderName, elementType)
					if (existingAdder?.declaringType != annotatedClass) {
						annotatedClass.addMethod('''«property.adderName»''') [
							val singular = 'a'+property.singular.toFirstUpper + '_' //The underscore is a quick workaround for reserved words
							addParameter(singular, elementType)
							body = ['''this.«property».add(«singular»);''']
						]
					}
					
					val existingRemover = annotatedClass.findMostSpecificMethod(property.removerName, elementType)
					if (existingRemover?.declaringType != annotatedClass) {
						annotatedClass.addMethod('''«property.removerName»''') [
							val singular = 'a'+property.singular.toFirstUpper + '_' //The underscore is a quick workaround for reserved words
							addParameter(singular, elementType)
							body = ['''this.«property».remove(«singular»);''']
						]
					}
					
					//Generate a setter that clears the collection an than adds any element passed in
					val existingSetter = annotatedClass.findMostSpecificMethod(property.setterName, propertyType)
					if (existingSetter?.declaringType != annotatedClass) {
						annotatedClass.addMethod(property.setterName) [
							addParameter(property, propertyType)
							val singular = 'a'+property.singular.toFirstUpper + '_'
							body = ['''
								this.«property».clear();
								for(«elementType» «singular» : «property»){
									«property.adderName»(«singular»);
								}
							''']	
						]
					}
				}

			}
		]

		val superConstructors = annotatedClass.superClass?.declaredConstructors
		//addWarning(annotatedClass, '''Superclass: «annotatedClass.superClass» - constructors: «superConstructors»''')
		val fieldsForConstr = annotatedClass.declaredFields.filter[!static && !type.isCollection && required]

		parameterLessConstructorCreated = false
		if (superConstructors.nullOrEmpty) {
			annotatedClass.addConstructor(null, fieldsForConstr)
		} else {		
			superConstructors.forEach[annotatedClass.addConstructor(it, fieldsForConstr)]
		}
		}catch (RuntimeException re){
			addError(annotatedClass, re.message)
		}
	}
	
	def MethodDeclaration parentPropertySetter(ClassDeclaration classDecl){
		val field = classDecl.parentPropertyField
		field?.declaringType?.findDeclaredMethod(field.simpleName.setterName)
	}
	
	def FieldDeclaration parentPropertyField(ClassDeclaration classDecl){
		var fields = classDecl.declaredFields.filter[hasAnnotation(Parent.name)]
		if(fields.empty){
			classDecl.superClass?.parentPropertyField
		} else {
			fields.head		
		}
	}

	def isRequired(FieldDeclaration field) {
		field.hasAnnotation(Required.name)
	}

	def findAnnotation(AnnotationTarget target, String annotationFqn) {
		target?.findAnnotation(findTypeGlobally(annotationFqn))
	}

	def hasAnnotation(AnnotationTarget target, String annotationFqn) {
		findAnnotation(target, annotationFqn) !== null
	}

	var parameterLessConstructorCreated = false //Dirty hack for not generating more than one parameterless constructor.
	
	def void addConstructor(MutableClassDeclaration classDecl, ConstructorDeclaration superConstructor, 
		Iterable<? extends FieldDeclaration> fields) {
		val INITIALIZER_PARAM = "initializer"
		if(superConstructor?.parameters?.last?.simpleName == INITIALIZER_PARAM){
			//Don't create constructors for superconstructors with initializer closures
			return
		}
		
		if(superConstructor !== null && superConstructor.parameters === null){
			//Sometimes we get invalid constructors here with "null" as parameters. Bug? Try to skip...
			return
		}	
		
		
		val parametersFromSuperConstructor = superConstructor?.parameters?.filter[classDecl.findDefaultValueField(it.simpleName) === null]	
		
		var parameterTypes = newArrayList
		if(parametersFromSuperConstructor !== null){
			parameterTypes.addAll(parametersFromSuperConstructor.map[type].toList)
		}
		parameterTypes.addAll(fields.map[type])
		
		//addWarning(classDecl, '''addConstructor for superConstructor «superConstructor» with super-params «superConstructor?.parameters?.map[simpleName]?.toString» and own params «parameterTypes»''')
		
		
		if(!parameterTypes.empty && classDecl.findDeclaredConstructor(parameterTypes) !== null){
			//Constructor already exists	
			return
		}
		
		if(parameterTypes.empty  ){
			if(parameterLessConstructorCreated){
				return
			}
			val declConstr = classDecl.declaredConstructors.filter[parameters.empty]
			//we always seem to get the default constructor here, even not declared.

			if(!declConstr.empty && declConstr.head.body !== null){
				return			
			}
			parameterLessConstructorCreated = true
			
		}
		
		val visibility = if(superConstructor !== null) superConstructor.visibility else Visibility.PUBLIC
		

		
			classDecl.addConstructor [ c |
				c.visibility = visibility
				parametersFromSuperConstructor?.forEach[c.addParameter(simpleName, type)]
				fields.forEach[c.addParameter(simpleName, type)]
				c.body = [
					'''
						«IF superConstructor !== null»
							super(«FOR p : superConstructor.parameters SEPARATOR ','»«classDecl.propertyNameOrDefaultValue(p.simpleName)»«ENDFOR»);
						«ENDIF»
						«FOR f : fields»
							this.«f.simpleName» = «f.simpleName»;
						«ENDFOR»
					''']
			]
			//Constructor with initializer closure
//			if(!classDecl.abstract){
//				classDecl.addConstructor [ c |
//					c.visibility = visibility
//					parametersFromSuperConstructor?.forEach[c.addParameter(simpleName, type)]
//					fields.forEach[c.addParameter(simpleName, type)]
//					c.addParameter(INITIALIZER_PARAM, newTypeReference(Procedures.Procedure1, newTypeReference(classDecl)))
//					c.body = [
//						'''
//							«IF superConstructor !== null»
//								super(«FOR p : superConstructor.parameters SEPARATOR ','»«classDecl.propertyNameOrDefaultValue(p.simpleName)»«ENDFOR»);
//							«ENDIF»
//							«FOR f : fields»
//								this.«f.simpleName» = «f.simpleName»;
//							«ENDFOR»
//							initializer.apply(this);
//						''']
//				]
//			}
		
	}
	
	def propertyNameOrDefaultValue(ClassDeclaration classDecl, String name){
		val defaultValueField = classDecl.findDefaultValueField(name)
		if(defaultValueField !== null){
			defaultValueField.simpleName
		} else {
			name
		}
	}

	def shallGenerateField(ClassDeclaration annotatedClass, FieldDeclaration existingField,
		MethodDeclaration existingGetter) {
		shallImplementProperty(annotatedClass, existingField, existingGetter) 
		&& existingField === null //if the field already exists in the class, it shall not be generated
		&& !existingGetter.hasAnnotation(Derived.name)
	}

	def static shallGenerateGetter(ClassDeclaration annotatedClass, FieldDeclaration existingField,
		MethodDeclaration existingGetter) {

		//if the getter already exists in the class, it shall not be generated
		existingGetter?.declaringType != annotatedClass
	}

	def static shallGenerateSetter(ClassDeclaration annotatedClass, FieldDeclaration existingField,
		MethodDeclaration existingSetter) {

		//if the setter already exists in the class, it shall not be generated
		existingSetter?.declaringType != annotatedClass //if the field is final, don't generate a setter
		&& (existingField === null || !existingField.final)
	}

	/**
	 * Decides whether the annotated class shall implement the property. 
	 */
	def static shallImplementProperty(ClassDeclaration annotatedClass, FieldDeclaration existingField,
		MethodDeclaration existingGetter) {
			
		//The class shall implement the property, if there is a field with according name
		existingField !== null
		
		//everything below does not work starting from xtend 2.4.3, since we somtimes get empty superclass stubs

//		//There is no getter yet declared in the class or its superclasses and its not going to be generated (by this processor)
//		(existingGetter === null) ||
//		//or the getter is implemented manually in the class itself, for example to wrap the field somehow before returning it							
//		(existingGetter.declaringType == annotatedClass && !existingGetter.abstract) ||
//		//or the getter is declared abstract in a superclass				
//		//and the class itself is not abstract
//		(existingGetter.declaringType != annotatedClass && existingGetter.abstract && !(annotatedClass.abstract))
}

def Iterable<? extends MethodDeclaration> allMethods(InterfaceDeclaration interfaceDeclaration) {
	val methods = newArrayList()
	methods.addAll(interfaceDeclaration.declaredMethods)
	interfaceDeclaration.extendedInterfaces.forEach [
		methods.addAll(allMethods(it.type as InterfaceDeclaration))
	]
	methods
}

def dispatch superClass(ClassDeclaration classDecl) {
	classDecl.extendedClass?.type as ClassDeclaration
}

def dispatch superClass(Type classDecl) {
	null
}

/**
	 * Finds the method here and in superclasses
	 */
def MethodDeclaration findMostSpecificMethod(extension ClassDeclaration classDecl, String name,
	TypeReference ... parameterTypes) {
	var method = findDeclaredMethod(name, parameterTypes)
	if (method === null) {
		method = classDecl.superClass?.findMostSpecificMethod(name, parameterTypes)
	}
	method
}

def MethodDeclaration findMostSpecificMethod(ClassDeclaration classDecl, MethodDeclaration method) {
	classDecl.findMostSpecificMethod(method.simpleName, method.parameters.map[type])
}

def MethodDeclaration findMethodInInterfaces(ClassDeclaration classDecl, MethodDeclaration method) {
	
	classDecl.interfaces.map[findMostSpecificMethod(method)].findFirst[it !== null] ?:
	classDecl.superClass?.findMethodInInterfaces(method)	
}

def MethodDeclaration findMostSpecificMethod(InterfaceDeclaration interfaceDecl, MethodDeclaration method) {
	
	
	 interfaceDecl.findDeclaredMethod(method.simpleName, method.parameters.map[type]) ?:
	 interfaceDecl.extendedInterfaces.map[type as InterfaceDeclaration].map[findMostSpecificMethod(method)].findFirst[it !== null]
}

def isGetter(MethodDeclaration m) {
	(m.simpleName.startsWith("get") && m.simpleName.length > 3 ||
		(m.simpleName.startsWith("is") && m.simpleName.length > 2 && m.returnType.isBoolean )
		) && m.parameters.empty
}

def isBoolean(TypeReference typeRef) {
	val type = typeRef.type
	type.qualifiedName == "java.lang.Boolean" ||
		(type instanceof PrimitiveType && (type as PrimitiveType).kind == PrimitiveType.Kind.BOOLEAN)
}

def isCollection(TypeReference typeRef) {
	typeRef.type.implementsInterface(Collection.name)
}

def dispatch interfaces(ClassDeclaration classDecl) {
	classDecl.implementedInterfaces.map[type as InterfaceDeclaration]
}

def dispatch interfaces(InterfaceDeclaration intDecl) {
	intDecl.extendedInterfaces.map[type as InterfaceDeclaration]
}

def dispatch Iterable<? extends InterfaceDeclaration> interfaces(Type type) {
	Collections.emptySet // Iterable<? extends InterfaceDeclaration>
}

def boolean implementsInterface(Type type, String interfaceFqn) {

	type.interfaces.exists [
		qualifiedName == interfaceFqn || it.implementsInterface(interfaceFqn)
	] || (type.superClass !== null && type.superClass.implementsInterface(interfaceFqn))
}

def propertyName(MethodDeclaration m) {
	val offset = if(m.returnType.isBoolean) 2 else 3
	m.simpleName.subSequence(offset, m.simpleName.length).toString.toFirstLower
}

def setterName(String propertyName) {
	'''set«propertyName.toFirstUpper»'''.toString
}

def adderName(String propertyName) {
	'''add«propertyName.toFirstUpper.singular»'''.toString
}

def removerName(String propertyName) {
	'''remove«propertyName.toFirstUpper.singular»'''.toString
}

def defaultValueFieldName(String propertyName) {
	'''«propertyName»_default'''.toString
}

def findDefaultValueField(ClassDeclaration classDelc, String propertyName) {
	classDelc.findDeclaredField(propertyName.defaultValueFieldName)
}

def singular(String propertyName) {
	if (propertyName.endsWith('s')) {
		propertyName.subSequence(0, propertyName.length - 1).toString
	} else {
		propertyName
	}
}

}
