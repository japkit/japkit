package de.japkit.roo.base.web;

import org.springframework.core.convert.converter.Converter;
import org.springframework.format.FormatterRegistry;

/**
 * TODO: Composite keys?
 * 
 * @author stefan
 * 
 * @param <E>
 */
public class EntityConverterUtil {

	public static <E> void registerConverters(Class<E> entityClass, FormatterRegistry formatterRegistry, CrudOperations<E> crudOperations,
			LabelProvider<E> labelProvider) {
		formatterRegistry.addConverter(entityClass, String.class, getEntityToStringConverter(labelProvider));
		formatterRegistry.addConverter(Long.class, entityClass, getIdToEntityConverter(crudOperations));
		formatterRegistry.addConverter(String.class, entityClass, getStringToEntityConverter(crudOperations));
	}

	public static <E> Converter<E, String> getEntityToStringConverter(final LabelProvider<E> labelProvider) {
		return new Converter<E, String>() {
			public String convert(E entity) {
				return labelProvider.getLabel(entity);
			}
		};
	}

	public static <E> Converter<Long, E> getIdToEntityConverter(final CrudOperations<E> crudOperations) {
		return new Converter<Long, E>() {
			public E convert(java.lang.Long id) {
				return crudOperations.find(id);
			}
		};
	}

	public static <E> Converter<String, E> getStringToEntityConverter(final CrudOperations<E> crudOperations) {
		return new Converter<String, E>() {
			public E convert(String id) {
				return crudOperations.find(new Long(id));
			}
		};
	}

}
