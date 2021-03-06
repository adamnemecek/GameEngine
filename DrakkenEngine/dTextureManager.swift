//
//  DKRTextureManager.swift
//  DrakkenEngine
//
//  Created by Allison Lindner on 19/05/16.
//  Copyright © 2016 Allison Lindner. All rights reserved.
//

import Metal
import MetalKit

internal class dTextureManager {
	private var _mtkTextureLoaderInternal: MTKTextureLoader!
	
	private var _mtkTextureLoader: MTKTextureLoader {
		get {
			if _mtkTextureLoaderInternal == nil {
				_mtkTextureLoaderInternal = MTKTextureLoader(device: dCore.instance.device)
			}
			
			return self._mtkTextureLoaderInternal
		}
	}
	
	private var _textures: [Int : MTLTexture] = [:]
	private var _renderTargetTextures: [Int : MTLTexture] = [:]
	
	private var _namedTextures: [String : Int] = [:]
	private var _namedRenderTargetTextures: [String : Int] = [:]
	
	private var _nextTextureIndex: Int = 0
	private var _nextRenderTargetIndex: Int = 0
	
	internal var screenTexture: MTLTexture?
	
	internal func create(_ file: String) -> Int {
		let texture = self.loadImage(file)!
		
		guard let indexed = _namedTextures[file] else {
			let _index = _nextTextureIndex
			_textures[_index] = texture
			_nextTextureIndex += 1
			
			_namedTextures[file] = _index
			
			return _index
		}
		
		_textures[indexed] = texture
		return indexed
	}
	
	internal func createRenderTarget(_ name: String, width: Int, height: Int) -> Int {
		let textureDesc = MTLTextureDescriptor.texture2DDescriptor(
			pixelFormat: .bgra8Unorm,
			width: width,
			height: height,
			mipmapped: false
		)
		textureDesc.usage.insert(.renderTarget)
		
		let texture = dCore.instance.device.makeTexture(descriptor: textureDesc)
		
		guard let indexed = _namedRenderTargetTextures[name] else {
			let _index = _nextRenderTargetIndex
			_renderTargetTextures[_index] = texture
			_nextRenderTargetIndex += 1
			
			_namedRenderTargetTextures[name] = _index
			
			return _index
		}
		
		_renderTargetTextures[indexed] = texture
		
		return indexed
	}
	
	internal func getTexture(_ id: Int) -> MTLTexture {
		return _textures[id]!
	}
	
	internal func getRenderTargetTexture(_ id: Int) -> MTLTexture {
		return _renderTargetTextures[id]!
	}
	
	internal func getTexture(_ file: String) -> MTLTexture {
		return getTexture(_namedTextures[file]!)
	}
	
	internal func getRenderTargetTexture(_ name: String) -> MTLTexture {
		return getRenderTargetTexture(_namedRenderTargetTextures[name]!)
	}
	
	internal func getID(_ name: String) -> Int? {
		return _namedTextures[name]
	}
	
	internal func getRenderTargetID(_ name: String) -> Int{
		return _namedRenderTargetTextures[name]!
	}
	
	private func loadImage(_ name: String) -> MTLTexture? {
		var _textureURL: URL?
		
		do {
			if let textureURL = Bundle(identifier: "drakkenstudio.DrakkenEngine")!.url(forResource: name, withExtension: nil, subdirectory: "Assets") {
				_textureURL = textureURL
			} else if let textureURL = dCore.instance.IMAGES_PATH?.appendingPathComponent(name) {
				_textureURL = textureURL
			}
			
			if _textureURL != nil {
				let texture = try _mtkTextureLoader.newTexture(withContentsOf: _textureURL!, options: nil)
				return texture
			} else {
				fatalError("Fail load image with name: \(name)")
			}
			
		} catch {
			fatalError("Fail load image with name: \(name)")
		}
		
		return nil
	}
    
    internal func deleteAll() {
        _textures.removeAll()
    }
}
