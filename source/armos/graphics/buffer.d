module armos.graphics.buffer;

import derelict.opengl3.gl;
import armos.graphics.vao;
import armos.math;
import std.variant;


/++
+/
class Buffer {
    public{

        /++
            BufferTypeを指定して初期化します．
        +/
        this(in BufferType bufferType){
            glGenBuffers(1, cast(uint*)&_id);
            _type = bufferType;
        }

        ///
        ~this(){
            glDeleteBuffers(1, cast(uint*)&_id);
        }

        /++
        +/
        void begin(){
            int savedID;
            glGetIntegerv(bindingEnum(_type), &savedID);
            _savedIDs ~= savedID;
            glBindBuffer(_type, _id);
        }

        /++
        +/
        void end(){
            import std.range;
            glBindBuffer(_type, _savedIDs[$-1]);
            if (_savedIDs.length == 0) {
                assert(0, "stack is empty");
            }else{
                _savedIDs.popBack;
            }
        }

        ///
        Buffer array(T)(in T[] array, in size_t dimention = 1,
                        in BufferUsageFrequency freq   = BufferUsageFrequency.Dynamic,
                        in BufferUsageNature    nature = BufferUsageNature.Draw)
        if(__traits(isArithmetic, T)){
            if(array.length == 0)return this;

            _array     = Algebraic!(const(int)[], const(float)[], const(double)[])(array);
            _dimention = dimention;
            _freq      = freq;
            _nature    = nature;

            updateGlBuffer;
            return this;
        }
        
        ///
        Buffer array(V)(in V[] array,
                        in BufferUsageFrequency freq   = BufferUsageFrequency.Dynamic,
                        in BufferUsageNature    nature = BufferUsageNature.Draw)
        if(isVector!V){
            if(array.length == 0)return this;
            V.elementType[] raw = new V.elementType[array.length*V.dimention];
            for (size_t i = 0, pos = 0, len = array.length; i < len; ++i, pos += V.dimention) {
                raw[pos .. pos + V.dimention] = array[i].elements;
            }
            this.array(raw, V.dimention, freq, nature);
            return this;
        }

        ///
        Buffer updateGlBuffer(){
            if(_array.type == typeid(const(float)[])){
                updateGlBuffer!(const(float));
            }else if(_array.type == typeid(const(double)[])){
                updateGlBuffer!(const(double));
            }else if(_array.type == typeid(const(int)[])){
                updateGlBuffer!(const(int));
            }
            return this;
        }

        ///
        size_t size()const{return _size;}

        ///
        BufferType type()const{return _type;}
    }//public

    private{
        int _id;
        int[] _savedIDs;
        BufferType _type;
        size_t _size;
        size_t _dimention;
        BufferUsageFrequency _freq;
        BufferUsageNature _nature;
        Algebraic!(const(int)[], const(float)[], const(double)[]) _array;

        void updateGlBuffer(T)(){
            auto arr = _array.get!(T[]);
            begin;
            immutable currentSize = arr.length * arr[0].sizeof;
             
            if(_size != currentSize){
                _size = currentSize;
                glBufferData(_type, _size, arr.ptr, usageEnum(_freq, _nature));
            }else{
                glBufferSubData(_type, 0, _size, arr.ptr);
            }
            
            import std.conv;
            if(_type != BufferType.ElementArray){
                static if(is(T == const(float))){
                    GLenum glDataType = GL_FLOAT;
                }else static if(is(T == const(double))){
                    GLenum glDataType = GL_DOUBLE;
                }else static if(is(T == const(int))){
                    GLenum glDataType = GL_INT;
                }
                glVertexAttribPointer(0,
                                      _dimention.to!int,
                                      glDataType,
                                      GL_FALSE,
                                      0,
                                      null);
            }
            end;
        }
    }//private
}//class Vbo

/++
+/
enum BufferType{
    Array             = GL_ARRAY_BUFFER,              /// Vertex attributes
    AtomicCounter     = GL_ATOMIC_COUNTER_BUFFER,     /// Atomic counter storage
    CopyRead          = GL_COPY_READ_BUFFER,          /// Buffer copy source
    CopyWrite         = GL_COPY_WRITE_BUFFER,         /// Buffer copy destination
    DispatchIndirect  = GL_DISPATCH_INDIRECT_BUFFER,  /// Indirect compute dispatch commands
    DrawIndirect      = GL_DRAW_INDIRECT_BUFFER,      /// Indirect command arguments
    ElementArray      = GL_ELEMENT_ARRAY_BUFFER,      /// Vertex array indices
    PixelPack         = GL_PIXEL_PACK_BUFFER,         /// Pixel read target
    PixelUnpack       = GL_PIXEL_UNPACK_BUFFER,       /// Texture data source
    Query             = GL_QUERY_BUFFER,              /// Query result buffer
    ShaderStorage     = GL_SHADER_STORAGE_BUFFER,     /// Read-write storage for shaders
    Texture           = GL_TEXTURE_BUFFER,            /// Texture data buffer
    TransformFeedback = GL_TRANSFORM_FEEDBACK_BUFFER, /// Transform feedback buffer
    Uniform           = GL_UNIFORM_BUFFER,            /// Uniform block storage
}

private GLenum bindingEnum(in BufferType bufferType){
    GLenum bindingType;
    switch (bufferType) {
        case BufferType.Array:
            bindingType =  GL_ARRAY_BUFFER_BINDING;
            break;
        case BufferType.AtomicCounter:
            bindingType = GL_ATOMIC_COUNTER_BUFFER_BINDING;
            break;
        case BufferType.CopyRead:
            bindingType = GL_COPY_READ_BUFFER_BINDING;
            break;
        case BufferType.CopyWrite:
            bindingType = GL_COPY_WRITE_BUFFER_BINDING;
            break;
        case BufferType.DispatchIndirect:
            bindingType = GL_DISPATCH_INDIRECT_BUFFER_BINDING;
            break;
        case BufferType.DrawIndirect:
            bindingType = GL_DRAW_INDIRECT_BUFFER_BINDING;
            break;
        case BufferType.ElementArray:
            bindingType = GL_ELEMENT_ARRAY_BUFFER_BINDING;
            break;
        case BufferType.PixelPack:
            bindingType = GL_PIXEL_PACK_BUFFER_BINDING;
            break;
        case BufferType.PixelUnpack:
            bindingType = GL_PIXEL_UNPACK_BUFFER_BINDING;
            break;
        case BufferType.Query:
            bindingType = GL_QUERY_BUFFER_BINDING;
            break;
        case BufferType.ShaderStorage:
            bindingType = GL_SHADER_STORAGE_BUFFER_BINDING;
            break;
        case BufferType.Texture:
            bindingType = GL_TEXTURE_BUFFER_BINDING;
            break;
        case BufferType.TransformFeedback:
            bindingType = GL_TRANSFORM_FEEDBACK_BUFFER_BINDING;
            break;
        case BufferType.Uniform:
            bindingType = GL_UNIFORM_BUFFER_BINDING;
            break;
        default : assert(0, "invalid value");
    }
    return bindingType;
}

/++
    Bufferの更新頻度を表すenumです．
+/
enum BufferUsageFrequency{
    Stream,  /// 読み込みも書き込みも一度のみ
    Static,  /// 書き込みが一度だけで，読み込みは何度も行われる
    Dynamic, /// 何度も読み書きが行われる
}

/++
    Bufferの読み書きの方法を表すenumです．
+/
enum BufferUsageNature{
    Draw, /// アプリケーション側から書き込まれ，OpenGLが描画のために読み込む
    Read, /// OpenGL側で書き込まれ，アプリケーション側で読み込む
    Copy, /// OpenGL側で書き込まれ，描画に用いられる
}

private static GLenum[BufferUsageNature][BufferUsageFrequency] usageEnumsTable(){
    GLenum[BufferUsageNature][BufferUsageFrequency] enums;
    enums[BufferUsageFrequency.Stream][BufferUsageNature.Draw] = GL_STREAM_DRAW;
    enums[BufferUsageFrequency.Stream][BufferUsageNature.Read] = GL_STREAM_READ;
    enums[BufferUsageFrequency.Stream][BufferUsageNature.Copy] = GL_STREAM_COPY;

    enums[BufferUsageFrequency.Static][BufferUsageNature.Draw] = GL_STATIC_DRAW;
    enums[BufferUsageFrequency.Static][BufferUsageNature.Read] = GL_STATIC_READ;
    enums[BufferUsageFrequency.Static][BufferUsageNature.Copy] = GL_STATIC_COPY;

    enums[BufferUsageFrequency.Dynamic][BufferUsageNature.Draw] = GL_DYNAMIC_DRAW;
    enums[BufferUsageFrequency.Dynamic][BufferUsageNature.Read] = GL_DYNAMIC_READ;
    enums[BufferUsageFrequency.Dynamic][BufferUsageNature.Copy] = GL_DYNAMIC_COPY;
    return enums;
};

static unittest{
    static assert(usageEnumsTable[BufferUsageFrequency.Static][BufferUsageNature.Draw] == GL_STATIC_DRAW);
}

private GLenum usageEnum(in BufferUsageFrequency freq, in BufferUsageNature nature){
    return usageEnumsTable[freq][nature];
}
