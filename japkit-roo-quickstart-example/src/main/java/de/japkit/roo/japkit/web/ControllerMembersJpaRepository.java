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
import de.japkit.roo.japkit.CommonLibrary;
import de.japkit.roo.japkit.CommonLibrary.nameFirstLower;
import de.japkit.roo.japkit.domain.DomainLibrary.findRepository;
import de.japkit.roo.japkit.web.JapkitWebScaffold.Repository;

@RuntimeMetadata
@Template(libraries=CommonLibrary.class)
public abstract class ControllerMembersJpaRepository {
	
	/**${this.class.superclass.toString()}*/
	@Field(commentLang="GStringTemplateInline")
	@Autowired
	private Repository repository;

	
	@Template(src="#{relatedEntities}", srcCollect="#{src.asType()}")
	abstract class RelatedEntityMembers{
		@Var
		class RelatedEntity {}
		
		@Var(fun={RelatedEntity.class, findRepository.class}, nullable=true)
		class RelatedEntityRepository {}
		
		@Var(fun={RelatedEntity.class, nameFirstLower.class})
		class repositoryFieldName {}
		
		@Field(cond="#{relatedEntityRepository !=null}")
		@Autowired
		private RelatedEntityRepository  $repositoryFieldName$;
		
		/**
		 * #{src}  #{src.singleValueType} #{repository}
		 */
		@Method(cond="#{relatedEntityRepository!=null}", src = "#{entityProperties}",  srcFilter="#{src.singleValueType.isSame(relatedEntity)}" , 			
				bodyCode = "return #{repositoryFieldName}.findAll();")
		protected abstract List<RelatedEntity> get$srcElementName$Choices();
	}

	@Method(imports = RepositoryAdapter.class,
			bodyCode = "return new RepositoryAdapter<#{fbo.code}>(repository);")
	protected abstract CrudOperations<FormBackingObject> crudOperations();

	

}
