package de.japkit.roo.japkit.web;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.Var;
import de.japkit.metaannotations.classselectors.ClassSelector;
import de.japkit.roo.base.web.CrudOperations;
import de.japkit.roo.base.web.RepositoryAdapter;
import de.japkit.roo.japkit.domain.DomainLibrary.findRepository;

@RuntimeMetadata
@Template
public abstract class ControllerMembersJpaRepository {
	@ClassSelector
	class Repository {}
	
	/**${this.class.superclass.toString()}*/
	@Field(commentLang="GStringTemplateInline")
	@Autowired
	private Repository repository;

	
	@Template(src="#{relatedEntities}", srcCollect="#{src.asType()}", srcVar="relatedEntity", 
			vars={
				@Var(name="repository", expr = "#{relatedEntity}", fun=findRepository.class, nullable=true),
				@Var(name="repositoryFieldName", expr = "#{relatedEntity.simpleName.toFirstLower}Repository")
			})
	abstract class RelatedEntityMembers{
		@Field(cond="#{repository!=null}")
		@Autowired
		private Repository $repositoryFieldName$;
		
		@ClassSelector
		class RelatedEntity {}
		
		/**
		 * #{src}  #{src.singleValueType} #{repository}
		 */
		@Method(cond="#{repository!=null}", src = "#{entityProperties}",  srcFilter="#{src.singleValueType.isSame(relatedEntity)}" , 			
				bodyCode = "return #{repositoryFieldName}.findAll();")
		protected abstract List<RelatedEntity> get$srcElementName$Choices();
	}

	@Method(imports = RepositoryAdapter.class,
			bodyCode = "return new RepositoryAdapter<#{fbo.code}>(repository);")
	protected abstract CrudOperations<FormBackingObject> crudOperations();

	

}
