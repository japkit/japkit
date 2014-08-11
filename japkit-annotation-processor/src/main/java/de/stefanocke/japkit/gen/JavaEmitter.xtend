package de.stefanocke.japkit.gen

import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.TypesExtensions
import de.stefanocke.japkit.support.TypesRegistry
import java.util.Collection
import java.util.List
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.PackageElement
import javax.lang.model.element.TypeElement
import javax.lang.model.element.TypeParameterElement
import javax.lang.model.element.VariableElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeMirror
import javax.lang.model.type.WildcardType
import org.apache.commons.lang3.StringEscapeUtils

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*

class JavaEmitter implements EmitterContext{

	//TODO: Refactoring
	extension TypesRegistry typesRegistry = ExtensionRegistry.get(TypesRegistry)
	extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions) 
	
	
	def importIfPossibleAndGetNameForCode(String shortName, String fqn) {
		if(importIfPossible(shortName, fqn)){
			shortName
		} else {
			fqn
		}
	}
	
	def importIfPossible(String shortName, String fqn) {
		if(!imports.containsKey(shortName)){
			imports.put(shortName, fqn)
		}
		fqn.equals(imports.get(shortName))	
	}
	
	
	//key is short name, value is fqn
	public val Map<String, String> imports = newHashMap()
	
	
	/**
	 * creates the code for the compilation unit for one type element.
	 */
	def compilationUnit(TypeElement typeElement){
		val packageName = typeElement.enclosingPackageName
		
		val typeDecl = code(typeElement)  //Instead of importsPlaceholder, we could let the methods register their type fqns...
		'''
		package «packageName»;
		«importStatements(typeElement)»

		«typeDecl»
		'''
	}
	
	def importStatements(TypeElement rootTypeElement){
		val fqnsToImport = imports.filter[shortName, fqn | 
			!fqn.startsWith("java.lang") &&
			!fqn.equals('''«rootTypeElement.qualifiedName».«shortName»'''.toString) //No import statements for inner types
		].values
		
		val fqnsToImportOrdered = orderImports(fqnsToImport)
		
		'''
		«FOR i : fqnsToImportOrdered»
		import «i»;
		«ENDFOR»
		'''
	}
	
	//TODO: Make configurable
	public val importOrder = #['java.', 'javax.', 'org.', 'com.', '*']
	
	public val importGroupsLongestFirst = newTreeSet([String s1, String s2 | -s1.length.compareTo(s2.length)]) => [addAll(importOrder)]
	
	def List<String> orderImports(Collection<String> fqnsToImport) {
		val fqnsToImportByGroup = newHashMap
		fqnsToImport.forEach[fqn |
			val group = importGroupsLongestFirst.findFirst[fqn.startsWith(it)] ?: '*'
			fqnsToImportByGroup.getOrCreateSortedSet(group).add(fqn)
		]
		importOrder.map[fqnsToImportByGroup.get(it) ?: emptySet].flatten.toList
	}
	
	def dispatch CharSequence code(TypeElement typeElement){
		switch typeElement.kind {
			case ElementKind.CLASS: codeForClass(typeElement)
			case ElementKind.INTERFACE: codeForInterface(typeElement)
			case ElementKind.ENUM: codeForEnum(typeElement) 
			case ElementKind.ANNOTATION_TYPE:  codeForAnnotationType(typeElement) //TODO
			default : unknownElement(typeElement)
		}
	}
	
	
	
	def codeForInterface(extension TypeElement element) {
		'''
		«element.docCommentCode»
		«element.annotationsCode»
		«element.modifiersCode»interface «simpleName» «element.typeParamsCode»«element.codeForInterfaces»{
			«element.enclosedElementsCode»
		}
		'''
	}
	
	def codeForAnnotationType(extension TypeElement element) {
		'''
		«element.docCommentCode»
		«element.annotationsCode»
		«element.modifiersCode»@interface «simpleName» {
			«element.enclosedElementsCode»
		}
		'''
	}
	
	def codeForClass(extension TypeElement element) {
		
		'''
		«element.docCommentCode»
		«element.annotationsCode»
		«element.modifiersCode»class «simpleName» «element.typeParamsCode»«element.codeForSuper»«element.codeForInterfaces»{
			«element.enclosedElementsCode»
		}
		'''
	}
	
	def codeForEnum(extension TypeElement element) {
		val enumConstants = enclosedElements.filter [kind==ElementKind.ENUM_CONSTANT]
		val classBodyDeclarations = enclosedElements.filter [kind!=ElementKind.ENUM_CONSTANT]
		'''
		«element.docCommentCode»
		«element.annotationsCode»
		«element.modifiersCode»enum «simpleName» «element.codeForInterfaces»{
			«FOR ec : enumConstants SEPARATOR ',\n'»
			«ec.docCommentCode»
			«ec.annotationsCode»
			«ec.simpleName»
			«ENDFOR»«IF !classBodyDeclarations.empty»;
			«ENDIF»
			«enclosedElementsCode(classBodyDeclarations)»
		}
		'''
	}
	
	def dispatch docCommentCode(GenElement element){
		if(element.comment == null) '''''' else '''/** «element.comment» */'''
	}
	
	def dispatch docCommentCode(Element element){
		''''''
	}
	
	
	def codeForInterfaces(TypeElement e){
		val keyword = if(e.kind == ElementKind.INTERFACE) "extends " else "implements "
		'''«FOR i : e.interfaces BEFORE keyword SEPARATOR ', ' AFTER ' '»«i.typeRef»«ENDFOR»'''
	}
	
	def codeForSuper(TypeElement e){
		'''«IF e.superclass != null && e.superclass.qualifiedName != "java.lang.Object"»extends «e.superclass.typeRef» «ENDIF»'''
	}
	
	def dispatch CharSequence code(extension VariableElement field){ 
		if(kind != ElementKind.FIELD){
			throw new IllegalArgumentException('''Only fields are allowed here, not «kind». VariableElement: «field»''')
		}
		
		val type = asType
		val constantExpr = field.constantExpressionCode
		'''
		«field.docCommentCode»	
		«field.annotationsCode»
		«field.modifiersCode»«type.typeRef» «simpleName»«IF constantExpr!=null» = «constantExpr»«ENDIF»;
		'''
		
	}
	
	def dispatch constantExpressionCode(VariableElement field){
		field.constantValue?.constantExpression
	}
	
	def dispatch constantExpressionCode(GenField field){
		field.constantExpr?.code(this)
	}
	
	def dispatch CharSequence code(extension ExecutableElement ee){
		switch ee.kind {
			case ElementKind.METHOD: codeForMethod(ee)
			case ElementKind.CONSTRUCTOR: codeForConstructor(ee)
			case ElementKind.STATIC_INIT: codeForStaticInitializer(ee)
			case ElementKind.INSTANCE_INIT: codeForInstanceInitializer(ee)
			default : unknownElement(ee)
			
		}
	}
	
	def codeForInstanceInitializer(ExecutableElement element) {
		''''''
	}
	
	def codeForStaticInitializer(ExecutableElement element) {
		''''''
	}
	
	def codeForConstructor(extension ExecutableElement e) {
		'''
		«e.docCommentCode»
		«e.annotationsCode»
		«e.modifiersCode»«e.typeParamsCode»«enclosingElement.simpleName»«e.codeForParameters»«e.codeForThrows»«block(e.codeForBody)»
		'''
	}
	
	def codeForMethod(extension ExecutableElement e) {
		val body = if(e.abstract || enclosingElement.kind == ElementKind.INTERFACE ){
			";"
		} else if(enclosingElement.kind == ElementKind.ANNOTATION_TYPE){
			'''«IF e.defaultValue !=null» default «e.defaultValue.annotationValueCode»«ENDIF»;'''
		}else {
			'''«block(e.codeForBody)»'''
		}
		
		'''
		«e.docCommentCode»
		«e.annotationsCode»
		«e.modifiersCode»«e.typeParamsCode»«returnType.typeRef» «simpleName»«e.codeForParameters»«e.codeForThrows»«body»
		'''
	}
	
	def codeForThrows(ExecutableElement e){
		'''«FOR ex : e.thrownTypes BEFORE ' throws ' SEPARATOR ', ' AFTER ' '»«ex.typeRef»«ENDFOR»'''
	}
	
	
	
	def dispatch codeForBody(GenExecutableElement e){
		if (e.body != null){ 
			e.body.code(this)
		} else {
			'''throw new UnsupportedOperationException("Method not implemented");''' 		
		}
	}
	
	def dispatch codeForBody(ExecutableElement e){
		'''throw new UnsupportedOperationException("Method not implemented");''' 		
	}
	
	def block(CharSequence statements){
		'''
		{
			«statements»
		}
		'''
	}
	
	def codeForParameters(ExecutableElement ee){
		codeListInlineOrWithLinebreaks(ee.parameters.map[codeForParameter].toList, '(', ', ',')')
	}
	
	def codeForParameter(extension VariableElement p){
		'''«p.annotationsCodeInline»«p.modifiersCode»«asType.typeRef» «simpleName»'''
	}
	
	def dispatch CharSequence code(Element element){
		unknownElement(element);
	}
	
	def dispatch typeRef(Void type){	
			"void"
	}
	
	def dispatch CharSequence typeRef(DeclaredType type){
		val rawType = if(type.erasure instanceof ErrorType){
			//The type itself is an error type
			val simpleName = type.erasure.toString   //TODO: Ist das wirklich immer ein simple name? Was ist mit inner classes? Zunächst ein assert...
			if(simpleName.contains('.')){
				throw new IllegalArgumentException('''Error type name «simpleName» is unexpectedly qualified.''');
			}
			val fqn =  typesRegistry.tryToGetFqnForErrorTypeSimpleName(type.erasure.toString)
			importIfPossibleAndGetNameForCode(simpleName, fqn)
		} else {
			//One of the type args is an error type
			val te = type.erasure.asTypeElement
			importIfPossibleAndGetNameForCode(te.simpleName.toString, te.qualifiedName.toString)
		}
		val result = '''«rawType»«FOR a : type.typeArguments BEFORE '<' SEPARATOR ', '  AFTER '>'»«a.typeRef»«ENDFOR»'''  //TODO: ? extends ... usw
		
		//messager.printMessage(Kind.NOTE, '''Resolved «type.class»  «type» with type args «type.typeArguments.map['''«class» "«it»"'''].join(',')» to «result»''')
		result
	}
	
	def dispatch CharSequence typeRef(WildcardType type){
		if(type.extendsBound!=null){
			'''? extends «typeRef(type.extendsBound)»'''
		} else if(type.superBound!=null){
			'''? super «typeRef(type.superBound)»'''
		} else {
			'?'
		}
	}
	
	def dispatch CharSequence typeRef(ArrayType type){
		'''«type.componentType.typeRef» []'''
	}
	
	def dispatch CharSequence typeRef(TypeMirror type){
		type.toString
	}
	
	override staticTypeRef(TypeMirror type){
		if (type == null) {
			"void"
		} else {
			staticTypeRef(type.simpleName.toString, type.qualifiedName.toString)
		}
	}
	
	override importIfPossible(DeclaredType type){
		importIfPossible(type.simpleName.toString, type.qualifiedName.toString)
	}
	
	override staticTypeRef(Class<?> clazz){
		staticTypeRef(clazz.simpleName, clazz.name)
	}
	
	def staticTypeRef(String shortName, String fqn){
		importIfPossibleAndGetNameForCode(shortName, fqn)
	}
	
	def staticTypeRef(TypeElement type){
		staticTypeRef(type.simpleName.toString, type.qualifiedName.toString)
	}
	
	def private enclosedElementsCode(Element element){
		enclosedElementsCode(element.enclosedElements)
	}
	
	def private enclosedElementsCode(Iterable<? extends Element> enclosedelements){
		
		'''
		«FOR e : enclosedelements»
		«e.code»
		
		«ENDFOR»
		'''
	}
	
	
	
	def private modifiersCode(Element element){
		//In javax.lang.model.element.Modifier the enum constants are declared in the suggested source code order for modifiers.
		//Thus, we sort by ordinal number.
		val orderedModifiers = element.modifiers.sortBy[ordinal]  
		'''«FOR m : orderedModifiers SEPARATOR ' ' AFTER ' '»«m»«ENDFOR»'''
	}
	
	def private annotationsCode(Element element){
		'''
		«FOR a : element.annotationMirrors»
		«a.annotationCode»
		«ENDFOR»
		'''
	}
	
	def private annotationsCodeInline(Element element){
		'''«FOR a : element.annotationMirrors SEPARATOR ' ' AFTER ' '»«a.annotationCode»«ENDFOR»'''
	}
	
	def CharSequence annotationCode(AnnotationMirror a){
		val typeName = staticTypeRef(a.annotationType)
		val values = a.elementValues.entrySet
		val elementValuePairs = if(values.empty){
			""
		} else if(values.size==1 && values.head.key.simpleName.contentEquals("value")){
			'''(«values.head.value.annotationValueCode»)'''
		} else {
			val avCode = values.map[av | '''«av.key.simpleName» = «av.value.annotationValueCode»'''].toList
			codeListInlineOrWithLinebreaks(avCode, '(', ', ', ')')
		}
		
		'''@«typeName»«elementValuePairs»'''
	}
	
	def codeListInlineOrWithLinebreaks(Iterable<? extends CharSequence> codeList, String before, String separator, String after) {
		val codeLength = codeList.map[length].reduce[l1, l2| l1 + l2] ?: 0
		
		if(codeLength<150){
			'''«before»«FOR c : codeList SEPARATOR separator»«c»«ENDFOR»«after»'''			
		} else {
			'''
			«before»
				«FOR c : codeList SEPARATOR separator»
				«c»
				«ENDFOR»
			«after»'''
		}
	}
	
	def dispatch CharSequence annotationValueCode(AnnotationValue value) {
		value.value.annotationValueCode
	}
	
	def dispatch CharSequence annotationValueCode(String value) {
		// buggy. Ein zeilenumbruch zu viel im letzten teilstring...
		//if(value.length>50)
		//	value.split("\\r?\\n").map['''"«StringEscapeUtils.escapeJava(it)»\n"'''].join("+\n")
		//else
			'''"«StringEscapeUtils.escapeJava(value)»"''' 
	}
	
	def dispatch CharSequence annotationValueCode(TypeMirror type) {
		'''«staticTypeRef(type)».class'''  
	}
	
	def dispatch CharSequence annotationValueCode(VariableElement ve) {
		'''«staticTypeRef(ve.enclosingElement as TypeElement)».«ve.simpleName»'''
	}
	
	
	def dispatch CharSequence annotationValueCode(AnnotationMirror a) {
		'''«a.annotationCode»'''
	}
	
	def dispatch CharSequence annotationValueCode(Void a) {
		'''null'''
	}
	
	def dispatch CharSequence annotationValueCode(List<? extends AnnotationValue> values) {
		if(values.size==1){
			values.head.annotationValueCode
		} else {
			val avCode = values.map[annotationValueCode].toList
			codeListInlineOrWithLinebreaks(avCode, '{',', ','}')
					
		}
	}
	
	def dispatch CharSequence annotationValueCode(Object value) {
		'''«value»'''
	}
	
	
	def dispatch Iterable<? extends TypeParameterElement> typeParams(Element e){
		throw new UnsupportedOperationException('''«e» does not support type parameters''');
	}
	
	def dispatch typeParams(TypeElement e){
		e.typeParameters
	}
	
	def dispatch typeParams(ExecutableElement e){
		e.typeParameters
	}
	
	def typeParamsCode(Element e){
		'''«FOR tpe : e.typeParams BEFORE '<' SEPARATOR ', ' AFTER '> '»«tpe.typeParamCode»«ENDFOR»'''	
	}
	
	def typeParamCode(TypeParameterElement tpe) {
		'''«tpe.simpleName»«tpe.boundsCode»'''
	}
	
	def boundsCode(TypeParameterElement tpe){
		val bounds = tpe.bounds.filter[it.qualifiedName != 'java.lang.Object']
		'''«FOR b : bounds BEFORE ' extends ' SEPARATOR ' & '»«b.typeRef»«ENDFOR»'''
	}
	
	def private unknownElement(Element element){
		//TODO: Warning or Error
		'''/**unsupported element: «element»
		*/
		'''
	}
	
	def isAbstract(Element e){
		e.modifiers.contains(Modifier.ABSTRACT)
	}
		
	def enclosingPackageName(TypeElement typeElement){
		val enclosingElement = typeElement.enclosingElement
		if(enclosingElement==null || !(enclosingElement instanceof PackageElement)){
			throw new IllegalArgumentException('''Enclosing element of «typeElement.simpleName» is not a package but «enclosingElement»''');
		}		
		val packageName = (enclosingElement as PackageElement).qualifiedName
		if(packageName==null || packageName.length == 0){
			throw new IllegalArgumentException('''Default package not supported: «typeElement.simpleName»''')
		}
		packageName
	}
	
	
}