package de.stefanocke.japkit.roo.japkit.web;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;

import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.roo.base.web.CrudOperations;
import de.stefanocke.japkit.roo.base.web.RepositoryAdapter;
import de.stefanocke.japkit.roo.japkit.domain.DomainLibrary.findRepository;

@RuntimeMetadata
@Template(
		templates=@TemplateCall(value = ControllerMembersJpaRepository.RelatedEntityMembers.class)
		)
public abstract class ControllerMembersJpaRepository {
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
