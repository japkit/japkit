package de.japkit.el.javael3

import java.util.Map
import jakarta.el.ELContext
import jakarta.el.ELResolver
import jakarta.el.ExpressionFactory
import jakarta.el.FunctionMapper
import jakarta.el.ImportHandler
import jakarta.el.VariableMapper
import jakarta.el.ValueExpression

/**
 * ELContext that uses JapkitELResolver and DynamicFunctionMapper.
 */
class JapkitELContext extends ELContext {
	
	val ELResolver elResolver;
	val ImportHandler importHandler;
	
	static val NoopFunctionMapper = new FunctionMapper {	
		override resolveFunction(String prefix, String localName) {
			return null;
		}	
	}
	
	static val NoopVariableMapper = new VariableMapper {
		
		override resolveVariable(String variable) {
			null
		}
		
		override setVariable(String variable, ValueExpression expression) {
		}
		
	}
	
	new(ExpressionFactory factory, Map<String, ? extends Object> vs){
		elResolver = new JapkitELResolver(factory, vs);
		
		importHandler = new JapkitImportHandler(vs); 
		
		// Force the use of the same context. For example, when the ELResolver internally calls getExpressionFactory(context)
		// Otherwise we run into some class loading issues..
		putContext(ExpressionFactory, factory)
	}
	
	override getELResolver() {
		elResolver
	}
	
	override getVariableMapper() {
		//There is a bug in the implementation of org.apache.el.lang.ExpressionBuilder which results in ELException for all
		//static methods. Only if a VariableMapper is set, there is no such exception. The referecnce implementation is slightly different
		//and doe not depend on a VariableMapper being set: 
		//https://github.com/jboss/uel/blob/master/impl/src/main/java/com/sun/el/lang/ExpressionBuilder.java#L254
		NoopVariableMapper
	}
	
	override getFunctionMapper() {
		//We cannot return null here, since for example org.apache.el checks for presence of a function mapper even if
		//our intention is just to call imported static methods.
		NoopFunctionMapper
	}
	
	override getImportHandler() {
		importHandler
	}
	
}
