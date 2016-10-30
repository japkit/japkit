package de.japkit.annotationtemplates

import javax.persistence.Entity;

import com.google.common.reflect.ClassPath;

println ClassPath.from(Entity.class.getClassLoader())
	.getTopLevelClasses(Entity.class.getPackage().getName())
	.findAll{it.load().isAnnotation()}
	.collect{ it.toString()+".class"}.join(', ')
