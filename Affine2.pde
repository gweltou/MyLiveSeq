public final class Affine2 {
  // From LibGDX Affine2
  public float m00 = 1, m01 = 0, m02 = 0;
  public float m10 = 0, m11 = 1, m12 = 0;

  /** Constructs an identity matrix. */
  public Affine2 () {
  }

  /** Constructs a matrix from the given affine matrix.
   *
   * @param other The affine matrix to copy. This matrix will not be modified. */
  public Affine2 (Affine2 other) {
    set(other);
  }

  /** Sets this matrix to the identity matrix
   * @return This matrix for the purpose of chaining operations. */
  public Affine2 idt () {
    m00 = 1;
    m01 = 0;
    m02 = 0;
    m10 = 0;
    m11 = 1;
    m12 = 0;
    return this;
  }


  /** Copies the values from the provided affine matrix to this matrix.
   * @param other The affine matrix to copy.
   * @return This matrix for the purposes of chaining. */
  public Affine2 set (Affine2 other) {
    m00 = other.m00;
    m01 = other.m01;
    m02 = other.m02;
    m10 = other.m10;
    m11 = other.m11;
    m12 = other.m12;
    return this;
  }


  /** Inverts this matrix given that the determinant is != 0.
   * @return This matrix for the purpose of chaining operations.
   * @throws GdxRuntimeException if the matrix is singular (not invertible) */
  public Affine2 inv () {
    float det = det();
    if (det == 0) throw new ArithmeticException("Can't invert a singular affine matrix");

    float invDet = 1.0f / det;

    float tmp00 = m11;
    float tmp01 = -m01;
    float tmp02 = m01 * m12 - m11 * m02;
    float tmp10 = -m10;
    float tmp11 = m00;
    float tmp12 = m10 * m02 - m00 * m12;

    m00 = invDet * tmp00;
    m01 = invDet * tmp01;
    m02 = invDet * tmp02;
    m10 = invDet * tmp10;
    m11 = invDet * tmp11;
    m12 = invDet * tmp12;
    return this;
  }


  /** Postmultiplies this matrix with the provided matrix and stores the result in this matrix. For example:
   *
   * <pre>
   * A.mul(B) results in A := AB
   * </pre>
   * @param other Matrix to multiply by.
   * @return This matrix for the purpose of chaining operations together. */
  public Affine2 mul (Affine2 other) {
    float tmp00 = m00 * other.m00 + m01 * other.m10;
    float tmp01 = m00 * other.m01 + m01 * other.m11;
    float tmp02 = m00 * other.m02 + m01 * other.m12 + m02;
    float tmp10 = m10 * other.m00 + m11 * other.m10;
    float tmp11 = m10 * other.m01 + m11 * other.m11;
    float tmp12 = m10 * other.m02 + m11 * other.m12 + m12;

    m00 = tmp00;
    m01 = tmp01;
    m02 = tmp02;
    m10 = tmp10;
    m11 = tmp11;
    m12 = tmp12;
    return this;
  }


  /** Postmultiplies this matrix by a translation matrix.
   * @param x The x-component of the translation vector.
   * @param y The y-component of the translation vector.
   * @return This matrix for the purpose of chaining. */
  public Affine2 translate (float x, float y) {
    m02 += m00 * x + m01 * y;
    m12 += m10 * x + m11 * y;
    return this;
  }


  /** Postmultiplies this matrix with a scale matrix.
   * @param scaleX The scale in the x-axis.
   * @param scaleY The scale in the y-axis.
   * @return This matrix for the purpose of chaining. */
  public Affine2 scale (float scaleX, float scaleY) {
    m00 *= scaleX;
    m01 *= scaleY;
    m10 *= scaleX;
    m11 *= scaleY;
    return this;
  }


  /** Calculates the determinant of the matrix.
   * @return The determinant of this matrix. */
  public float det () {
    return m00 * m11 - m01 * m10;
  }


  /** Get the x-y translation component of the matrix.
   * @param position Output vector.
   * @return Filled position. */
  public PVector getTranslation (PVector position) {
    position.x = m02;
    position.y = m12;
    return position;
  }


  /** Applies the affine transformation on a vector. */
  public void applyTo (PVector point) {
    float x = point.x;
    float y = point.y;
    point.x = m00 * x + m01 * y + m02;
    point.y = m10 * x + m11 * y + m12;
  }


  @Override
  public String toString () {
    return "[" + m00 + "|" + m01 + "|" + m02 + "]\n[" + m10 + "|" + m11 + "|" + m12 + "]\n[0.0|0.0|0.1]";
  }
}
