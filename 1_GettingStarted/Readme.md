## Getting Started

### Creating a Window

We need a window and an OpenGL context to draw in. This is OS specific, libraries exist to help e.g. GLUT, SDL, SFML and GLFW.
Using GLFW we can create an OpenGL context, as well as a window with parameters and also handle user input. It also provides callbacks for useful events, such as user input or window resizing.

Another OS specific issue is the location of the OpenGL functions provided by a particular graphics card drivers. GLAD is a library that helps to simplify this process.

Double buffering is a technique that makes changes to a secondary buffer object, then when complete updates the main buffer in one go, rather than updating the main buffer incrementally. Resulting in smoother frame transitions.

See [the code](Hello/main.cpp) for actual usage.

### Basic Triangle

The graphics pipeline takes a 3D object and outputs 2D pixels to the screen. The main interactions a programmer has with the pipeline is with the vertex and fragment shader programs. 

The vertex shader operates on a 3D vertex and outputs a 3D vertex that has been manipulated in some way by the program. The fragment shader takes a rasterized fragment and is used to determine the final colour of the output pixel.

OpenGL uses normalized device coordinates (NDC) to define vertices, where *x*, *y* and *z* range from *-1* to *+1*.

To send vertices to the vertex shader we need to store them in a *vertex buffer object* (VBO). Buffers are generated using:

```c
unsigned int VBO;
glGenBuffers(1, &VBO); // first arg is num of buffers to gen
```

A buffer needs to bound to an OpenGL buffer type to be usable, for a VBO the type is `GL_ARRAY_BUFFER` and its bound using:

```c
glBindBuffer(GL_ARRAY_BUFFER, VBO);
```

After the buffer is bound any buffer operations on the `GL_ARRAY_BUFFER` type will effect the *VBO* object we created and bound. The vertex data can be copied into the buffer with:

```c
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
```

The fourth arg of `glBufferData` indicates how changeable the data is likely to be, `GL_STATIC_DRAW` means it will chnage very rarely, other options are `GL_DYNAMIC_DRAW` and `GL_STREAM_DRAW` for different degrees of dynamic data.

Shaders are separate programs written in the OpenGL Shading Language (GLSL). The most basic of vertex shaders can be seen below.

```glsl
#version 330 core
layout (location = 0) in vec3 aPos;

void main()
{
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
```

A shader program begins with a version declaration and optionally a profile, in the example GLSL 3.3 and the core profile. All input vertex attributes are defined with the *in* keyword. In this case the location of the attribute is also given with `layout (location = 0)`, this is used later to send the shader the vertex data to the correct place. The ouptut vertex is assigned to `gl_Position`.

In a similar way to buffer creation we must create a shader object, and assign the source (a string in this case) to the object, then finally compile the shader for use.

```c
unsigned int vertexShader;
vertexShader = glCreateShader(GL_VERTEX_SHADER);
glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
glCompileShader(vertexShader);
```

Fragment shaders are created in analogous manner, where the code would specify `out` vectors.

```glsl
#version 330 core
out vec4 FragColor;

void main()
{
    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
```

Next, the two shaders need to be attached to a shader program.

```c
unsigned int shaderProgram;
shaderProgram = glCreateProgram();
glAttachShader(shaderProgram, vertexShader);
glAttachShader(shaderProgram, fragmentShader);
glLinkProgram(shaderProgram);
glUseProgram(shaderProgram);
```

The shader compilation and linking procedures can be checked for errors, see [the code](Hello/main.cpp).

The next step is to define what data we will give to the vertex shader, vertex attributes allow us to send arbitrary data to the shader. We define it with `glVertexAttribPointer`, for example:

```c
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0); // references location set within the shader
```

A **vertex array object** (VAO) allows us to essentially save all this *vertex buffer* configuration, meaning it can be easily re-used. In fact, such an object is required by OpenGL Core. The definition is similar to a *VBO*.

```c
unsigned int VAO;
glGenVertexArrays(1, &VAO);
glBindVertexArray(VAO);
// bind the VBO (saved by VAO)
glBindBuffer(GL_ARRAY_BUFFER, VBO);
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0);  
// [render loop]
glUseProgram(shaderProgram);
glBindVertexArray(VAO);
```

To eventually draw the triangle we use `glDrawArrays(GL_TRIANGLES, 0, 3);`

A final type of buffer to mention is an **Element Buffer Object** (EBO). Used when we want to draw multiple objects from a set of vertices, say two triangles to make a rectangle. Instead of duplicating vertices the EBO is an array of indices into the vertex buffer. A *VAO* will also keep track of a bound *EBO*.

### Shaders

Shaders are programs that run directly on the GPU, and are written in GLSL which is a C-like language. The general structure of a shader is a version statement followed by input and output variables, then uniforms. The entry point is the `void main()` method.

For vertex shaders we call each input variable a *vertex attribute*, OpenGL provides a minimum of 16 but different hardware may provide more.

GLSL has types like other languages, e.g. `int, uint, float, bool`. It also has vector and matrix types. Vectors can have 1-4 elements denoted `vec, vec2, vec3, vec4` for *floats*, other vector types are `bvec, ivec, uvec, dvec` for *bool, int, uint* and *doubles*. Vector elements can be accessed with `xyzw`, `rgba` (colors) or `stpq` (textures). Swizzling allows the element access to be mixed up or repeated e.g. `.xxyy, .wxyz, .yyyy`. Vector constructors can take a vector variable to be fully or partially substituted for its params e.g. `vec4(some_vec2, 0.0, 1.0)`.

Shaders are not able to communicate with each other directly, but only through their input and output. Using the `in` and `out` keywords we can define these variables. If the name of an output matches the input of the next shader, then OpenGL will link them together. 

Vertex shaders must have input which it receives directly from the vertex data. We configure the vertex data in the CPU side of our program and use *location metadata* on our input variable so the shader can find it, `layout (location = 0) in vec3 pos;`. The `layout` qualifier can be left out and instead use `glGetAttribLocation` in the OpenGL (CPU) code. Fragment shaders, on the other hand, must have a `vec4` output for color.

#### Uniforms

Uniforms are a another way to pass data from the CPU side to the GPU shader programs. Uniforms are global meaning they are defined on the shader program object and can be accessed by any shader linked to the program. They will also hold the value they have been assigned, until they are updated or reset. If you declare a uniform in your GLSL, but don't use it there, the compiler will remove it - causing annoying errors.

In GLSL we simply use the `uniform` keyword to define a uniform `uniform vec4 aVar;`. To assign some data to the uniform in GLSL we need to find the location of it in the shader, `glGetUniformLocation(shaderProgram, "aVar")` it returns *-1* if the location is not found. The value is then assigned with `glUniform4f(location, aVector4)`. As with other GLSL functions use the appropriate `glUniformXX()` method for the uniform type. It is not necessary to have called `glUseProgram` before getting the location, but it must be called before updating a uniform as the update will be on the active shader program.

#### Vertex Attributes Plus

As mentioned previously vertex data can hold more than just vertex coordinates, in fact any arbitrary data we require can be added. For example a color could be defined for each vertex, we simply add another three floats (r, g, b) after each vertex triple. The vertex attribute pointers need to be updated so the new data can retrieved correctly. The original position attribute stays much the same, but the *stride* value needs to be increased to skip the color values.

```c
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0);
```

The color attribute looks similar, with a different location (first arg) and offset (last arg).

```c
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3* sizeof(float)));
glEnableVertexAttribArray(1);
```

In the shader we define a new input along the lines of the position variable.

```c
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
```

Fragment shaders interpolate all its inputs across the fragments that it generates.
If we send this new vertex color to the fragment shader and use it as output we see a spectrum of colors on our triangle. From the defined vertex colors on the tree vertices of the triangle, the shader produces a linear interpolation based on the generated fragments location in relation to the specified vertices. For example 10% blue, 90% green, 0% red.

See the [code](Shaders/shader.h) for a method to load shaders from text files, rather than inserting strings into the C program.

### Textures

Textures are images applied to a 3D object to give it a realistic look. In order to map a texture to an object each vertex needs a *texture coordinate* that specifies what part of the image it should sample from. Fragment interpolation will fill in the rest, in a similar way to the vertex colours in the previous section.

Texture coordinates range from *0* to *1* across the 2D plane with the origin at the bottom left. The actual sampling of the texture using these coordinates can be done in a number of ways. The main options for controlling this are *texture wrapping* and *texture filtering*.

#### Texture Wrapping

When the texture coordinates are given outside the 0-1 range the default behavior is to repeat the image in the appropriate direction `GL_REPEAT`. Other wrapping options are `GL_MIRRORED_REPEAT` (like repeat buy alternately mirrored), `GL_CLAMP_TO_EDGE` (clamped to 0,1 gives a stretched edge) and `GL_CLAMP_TO_BORDER` (coordinates outside the range are given a defined color). The wrapping options can be set per axis *s* and *t* (equivalent to *x* & *y*) using the `glTexParameter*` function.

```c
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
```

The first argument specifies the texture target, 2D textures in this case (1D and 3D textures also exist). Second argument defines the axis we are setting the wrapping for. The last argument is the wrapping type we want to apply.

#### Texture Filtering

Texture coordinates don't depend on texture resolution, but can have any floating point value. OpenGL needs to map a texture pixel (texel) to a texture coordinate, like wrapping there are a number of ways to determine the pixel to use. This is mainly of concern when applying low resolutions textures onto large 3D objects. There are two main options, nearest neighbor `GL_NEAREST` selects the pixel whose centre is closest to the coordinate. Bilinear filtering `GL_LINEAR` creates a linear interpolation between all the pixels around the coordinate based on distance. `GL_NEAREST` results in a sharp but blocky image, where as `GL_LINEAR` is more smooth, but inclined to have a blurred look.

The filtering can be set for *magnifying* and *minifying* operations i.e. scaling up or down. We use `glTexParameter` again to set the filtering.

```c
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
```

In a 3D scene it makes no sense to have object in the distance using the same high resolution textures the an object in the foreground close to the camera uses. It wastes memory and can also produce artifacts on the distance objects, as they are so small compared to texture applied to them. 

A solution is to use *mipmaps*, which are a series of texture images each half the size of the previous one. Then based on the distance of an object from the camera we can select an appropriately sized *mipmap*. OpenGL can generate *mipmaps* for you based on an existing texture with `glGenerateMipmaps(GL_TEXTURE_2D)`.

To use *mipmaps* we set the minifying filter to one of the four *mipmap* filters `GL_NEAREST_MIPMAP_NEAREST`, `GL_NEAREST_MIPMAP_LINEAR`, `GL_LINEAR_MIPMAP_NEAREST` and `GL_LINEAR_MIPMAP_LINEAR`. Using a *mipmap* filter for magnifying will do nothing, and generate an error code.

```c
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
```

#### Loading & Creating Textures

Firstly, the texture image needs to be loaded into your program. A popular choice is the `stb_image.h` [library](https://github.com/nothings/stb/blob/master/stb_image.h).

To load the image with `stbi_load` with arguments for file location and int references to store width, height and number of channels of the image.

```c
int width, height, nrChannels;
unsigned char *data = stbi_load("container.jpg", &width, &height, &nrChannels, 0); 
```

To create the texture we need to declare it with an ID, like we did with Buffers or any other OpenGL objects.

```c
unsigned int texture;
glGenTextures(1, &texture); // arg is number of textures to gen
glBindTexture(GL_TEXTURE_2D, texture);
```

To generate a texture from the image we use `glTexImage2D`.

```c
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
```

The second arg defines the *mipmap* level in this case its the base level `0`. The last three args are the image format, datatype and image data respectively. The *mipmap* levels can be specified manually with a call to `glTexImage2D` for each level. As mentioned before we can alternatively auto generate the *mipmaps* with `glGenerateMipmap(GL_TEXTURE_2D)`.

We need to add the texture coordinates to our set of vertex attributes and update our attribute pointers to read the new values correctly. New input and ouput variables are added to the vertex shader to send the tex coords to the fragment shader. The actual texture object is referenced in the fragment shader as a `Sampler2D` *uniform* (3D or 1D also possible). The actual sampling takes place with the `texture(texture1, coords1)` function.

```glsl
out vec4 FragColor;
  
in vec3 ourColor;
in vec2 TexCoord;

uniform sampler2D ourTexture;

void main()
{
    FragColor = texture(ourTexture, TexCoord);
}
```

By default (with most drivers) the location of a single texture is handled by OpenGL, so we don't have to specify a value to the `Sampler2D` uniform. However, if we want multiple textures to be available to the fragment shader the locations must be defined. This location is known as a *texture unit*, there is a minimum of 16 (0 to 15). To set the location:
  - set the active texture unit `glActiveTextureUnit(GL_TEXTURE0)`
  - then bind a texture object to the active texture unit `glBindTexture(GL_TEXTURE_2D, texture)`
  - finally set the uniform `glUniform1i(glGetUniformLocation(shader.ID, "texture"), 0)`

OpenGL expects the zero coordinate of the y-axis to be on the bottom side of an image, where most images have zero at the top of the y-axis. `stb_image.h` can flip images on load by calling `stbi_set_flip_vertically_on_load(true)`.