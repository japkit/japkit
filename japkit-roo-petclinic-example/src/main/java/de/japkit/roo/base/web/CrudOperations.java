package de.japkit.roo.base.web;

import java.util.List;

public interface CrudOperations<T> {

	public abstract void remove(Long id);

	public abstract T merge(T fbo);

	public abstract void persist(T fbo);

	public abstract T find(Long id);

	public abstract long count();

	public abstract List<T> findAll(String sortFieldName, String sortOrder);

	public abstract List<T> findEntries(Integer firstResult, Integer maxResults, String sortFieldName, String sortOrder);

}