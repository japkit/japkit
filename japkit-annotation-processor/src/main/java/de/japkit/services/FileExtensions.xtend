package de.japkit.services

import java.io.File
import java.io.IOException
import java.util.Set

class FileExtensions {
	val Set<File> existingDirs = newHashSet	
	
	def public void ensureParentDirectoriesExist(File f) throws IOException {     
            val parent = f.getParentFile();
            
            if(existingDirs.contains(parent)) return;
            
            if (parent != null && !parent.exists()) {
                if (!parent.mkdirs()) {
                    // could have been concurrently created
                    if (!parent.exists() || !parent.isDirectory())
                        throw new IOException("Unable to create parent directories for " + f); //$NON-NLS-1$
                }
                existingDirs.add(parent)
            }
            
    }
  }