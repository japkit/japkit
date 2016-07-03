package de.japkit.roo.base.web;

import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.Sort.Direction;
import org.springframework.data.jpa.repository.JpaRepository;

public class RepositoryAdapter<T> implements CrudOperations<T> {

	private JpaRepository<T, Long> repository;

	public RepositoryAdapter(JpaRepository<T, Long> repository) {
		this.repository = repository;
	}

	@Override
	public void remove(Long id) {
		repository.delete(id);

	}

	@Override
	public T merge(T fbo) {
		return repository.save(fbo);
	}

	@Override
	public void persist(T fbo) {
		repository.save(fbo);
	}

	@Override
	public T find(Long id) {
		return repository.findOne(id);
	}

	@Override
	public long count() {
		return repository.count();
	}

	@Override
	public List<T> findAll(String sortFieldName, String sortOrder) {
		if (sortFieldName != null) {
			Sort sort = new Sort(Direction.fromStringOrNull(sortOrder), sortFieldName);
			return repository.findAll(sort);
		} else {
			return repository.findAll();
		}
	}

	@Override
	public List<T> findEntries(Integer firstResult, Integer maxResults, String sortFieldName, String sortOrder) {
		Sort sort = null;
		if (sortFieldName != null) {
			sort = new Sort(Direction.fromStringOrNull(sortOrder), sortFieldName);
		}

		Pageable pageable = new PageRequest(firstResult / maxResults, maxResults, sort);
		return repository.findAll(pageable).getContent();
	}

}
