package de.japkit.roo.base.web;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.FactoryBean;
import org.springframework.beans.factory.annotation.Autowired;

public class ResourceBundleNameRegistry implements FactoryBean<String[]>{
	@Autowired(required=false)
	private List<ResourceBundleNameProvider> resourceBundleNameProvider = new ArrayList<ResourceBundleNameProvider>();
	
	private String path = "WEB-INF/i18n/"; //
	
	private String common;
	
	public String getCommon() {
		return common;
	}
	
	public void setCommon(String common) {
		this.common = common;
	}
	
	public String getPath() {
		return path;
	}

	public void setPath(String path) {
		this.path = path;
	}

	public String[] getResourceBundleNames(){
		List<String> result = new ArrayList<String>();
		for (ResourceBundleNameProvider provider : resourceBundleNameProvider) {
			String[] resourceBundleBaseNames = provider.getResourceBundleBaseNames();
			for (String baseName : resourceBundleBaseNames) {
				result.add(path+baseName);
			}
		}
		if(common!=null){
			String[] commonNames = common.split(",");
			for (String baseName : commonNames) {
				result.add(path+baseName.trim());
			}
		}
		return result.toArray(new String[result.size()]);
	}

	@Override
	public String[] getObject() throws Exception {
		return getResourceBundleNames();
	}

	@Override
	public Class<?> getObjectType() {
		return String[].class;
	}

	@Override
	public boolean isSingleton() {
		return true;
	}
	
}
