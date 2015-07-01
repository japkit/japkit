package de.japkit.roo.japkit.web;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.ui.Model;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.Var;
import de.japkit.roo.base.web.CrudOperations;
import de.japkit.roo.base.web.RepositoryAdapter;
import de.japkit.roo.japkit.CommonLibrary;
import de.japkit.roo.japkit.CommonLibrary.nameFirstLower;
import de.japkit.roo.japkit.domain.DomainLibrary.findRepository;
import de.japkit.roo.japkit.domain.DomainLibrary.isEntity;
import de.japkit.roo.japkit.web.JapkitWebScaffold.Repository;

@RuntimeMetadata
@Template(libraries=CommonLibrary.class)
public abstract class ControllerMembersJpaRepository {
	
	@Field
	@Autowired
	private Repository repository;
	
	@Var(expr = "#{viewProperties}", filterFun = isEntity.class)
	class entityProperties{}
	
	@Template(src="#{entityProperties}", srcCollect="#{src.singleValueType.asElement}", srcToSet = true) 
	abstract class RelatedEntityMembers{
		@Var(expr="#{src.asType()}")
		class RelatedEntity {}
		
		@Var(fun={RelatedEntity.class, findRepository.class})
		class RelatedEntityRepository {}
		
		@Var(fun={RelatedEntityRepository.class, nameFirstLower.class})
		class repositoryFieldName {}
		
		@Field
		@Autowired
		private RelatedEntityRepository  $repositoryFieldName$;
		
		@Method(srcFun=entityProperties.class,  srcFilter="#{src.singleValueType.isSame(relatedEntity)}" , 			
				bodyCode = "return #{repositoryFieldName}.findAll();")
		protected abstract List<RelatedEntity> get$srcElementName$Choices();
	}

	@Method(imports = RepositoryAdapter.class,
			bodyCode = "return new RepositoryAdapter<#{fbo.code}>(repository);")
	protected abstract CrudOperations<FormBackingObject> crudOperations();

	//TODO: Eigentlich singleValueType.
	/**
	 * @japkit.bodyCode <code>uiModel.addAttribute("${src.name}Choices", get${src.name.toFirstUpper}Choices());</code>
	 */
	@Method(bodyIterator="entityProperties")
	abstract void addEntityChoices(Model uiModel);
	

}
