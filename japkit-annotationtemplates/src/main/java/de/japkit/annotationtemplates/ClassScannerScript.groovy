package de.japkit.annotationtemplates

import jakarta.persistence.Entity
import jakarta.validation.Valid
import jakarta.validation.constraints.NotNull;

import com.google.common.reflect.ClassPath;

println ClassPath.from(Entity.class.getClassLoader())
	.getTopLevelClasses(Entity.class.getPackage().getName())
	.findAll{it.load().isAnnotation()}
	.collect{ it.toString()+".class"}.join(', ')

println ClassPath.from(Valid.class.getClassLoader())
	.getTopLevelClasses(Valid.class.getPackage().getName())
	.findAll{it.load().isAnnotation()}
	.collect{ it.toString()+".class"}.join(', ')
	
println ClassPath.from(NotNull.class.getClassLoader())
	.getTopLevelClasses(NotNull.class.getPackage().getName())
	.findAll{it.load().isAnnotation()}
	.collect{ it.toString()+".class"}.join(', ')