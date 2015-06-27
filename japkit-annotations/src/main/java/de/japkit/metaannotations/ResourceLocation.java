package de.japkit.metaannotations;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Map;

/**
 * Locations for resource files. The relative paths are just proposals according
 * to usual conventions and can be overridden by processor options. 
 * (name of the option is enum to lower case, for example "test_resources" )
 * <p>
 * At least,
 * the project directory must be set as processor option to use the paths.
 * <p>
 * Also, there is no mechanism that automatically includes those directories in
 * your JAR or WAR. So, if they are not Maven defaults (like
 * src/main/resources), you have to include them yourself as resources or web
 * resources directories in your POM.
 * 
 * @author stefan
 * 
 */
public enum ResourceLocation {

	RESOURCES("src/main/resources"),

	TEST_RESOURCES("src/main/test-resources"),

	GENERATED_SOURCES("target/src/main/generated-sources"),

	GENERATED_TEST_SOURCES("target/src/main/generated-test-sources"),
	
	GENERATED_RESOURCES("target/src/main/generated-resources"),

	GENERATED_TEST_RESOURCES("target/src/main/generated-test-resources"),

	WEBAPP("src/main/webapp"),
	
	WEBINF("src/main/webapp/WEB-INF"),
	
	GENERATED_WEBAPP("target/src/main/webapp"),
	
	GENERATED_WEBINF("target/src/main/webapp/WEB-INF"),
	
	/**
	 * The class path of the annotation processor. Unfortunately, the annotation processing API does not allow to access resources
	 * on the classpath of the project. As a workaround, put resources required by your trigger annotations on the classpath of
	 * the processor.
	 */
	CLASSPATH(null, true),
	
	CLASSPATH_TEMPLATES("templates", true)
	;
	

	public static final String PROJECT_DIR = "projectDirectory";
	
	private String relativePath;
	
	private boolean isFromClassPath;
	
	private ResourceLocation(String relativePath) {
		this.relativePath = relativePath;
	}
	
	private ResourceLocation(String relativePath, boolean isFromClassPath) {
		this.relativePath = relativePath;
		this.isFromClassPath = isFromClassPath;
	}
	
	public URL getUrl(Map<String, String> options, String resourcePath, String fileName) throws MalformedURLException{
		if(isFromClassPath){
			String path = ((relativePath!=null) ?  relativePath+"/" : "") + resourcePath +"/" + fileName;
			return getClass().getClassLoader().getResource(path);
		} else {
			File file = getFile(options, resourcePath, fileName);
			return file.toURI().toURL();
		}
		
	}

	public File getFile(Map<String, String> options, String resourcePath, String fileName) {
		File dir = new File(getLocationDir(options), resourcePath);	
		File file = new File(dir, fileName);
		return file;
	}

	public File getLocationDir(Map<String, String> options) {
		if(isFromClassPath){
			throw new IllegalArgumentException("Classpath resource location "+name()+ " is not allowed here.");
		}
		String projectDir = options.get(PROJECT_DIR);
		if(projectDir==null){
			throw new IllegalArgumentException("Processor option "+PROJECT_DIR+" must be set to use resource locations.");
		}
		String relativePath = options.get(this.name().toLowerCase());
		if(relativePath==null){
			relativePath = this.relativePath;
		}
			
		File file = new File(projectDir, relativePath);
		return file;
	}
	

}
