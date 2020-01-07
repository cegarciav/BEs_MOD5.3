import scipy.io.wavfile as wav
import numpy as np
import os
from random import shuffle

files_folder = "spoken_digit_dataset/"
duree_trame = 0.030
order = 10
omega_v = 1
omega_d = 1
omega_h = 1

"""Fe, s1 = wav.read(files_folder + "0_jackson_0.wav")
_, s2 = wav.read(files_folder + "0_jackson_5.wav")
window_semi_size = int(Fe * duree_trame / 2)"""

def get_r_vector(order, window):
    r_vector = []
    for index in range(order + 1):
        vect_1 = window[:len(window) - index]
        vect_2 = window[index:]
        r_vector.append(sum(vect_1 * vect_2) / len(vect_1))
    return r_vector

def get_r_matrix(r_vector):
    size = len(r_vector)
    mat = np.zeros((size, size))
    for i in range(size):
        for j in range(size):
            mat[i, j] = r_vector[abs(i - j)]
    return mat

def get_a_vector(matrix):
    inverse_m = np.linalg.inv(matrix)
    sigma_vector = np.zeros(len(matrix))
    sigma_vector[0] = 1
    mult = np.dot(inverse_m, sigma_vector)
    a_vector = mult / mult[0]
    return a_vector[1:]

def lpc_coeffs(order, window):
    r_vector = get_r_vector(order, window)
    r_matrix = get_r_matrix(r_vector)
    a_vector = get_a_vector(r_matrix)
    return a_vector

def lpc_coeffs_list(signal, window_semi_size, order):
    s_length = len(signal)
    window_size = window_semi_size * 2
    start = 0
    lpc_list = []
    while True:
        window = signal[start : start + window_size]
        lpc_list.append(lpc_coeffs(order, window))
        start += window_semi_size
        if start + window_size > s_length:
            break
    return lpc_list

def euclidean_distance(vect1, vect2):
    return np.sqrt(sum((vect1 - vect2) ** 2))

def distance_elastique(coeffs_1, coeffs_2, omega_v, omega_d, omega_h):
    distance_matrix = np.zeros((len(coeffs_1), len(coeffs_2)))
    # on calcule la première distance (0,0)
    distance_matrix[0,0] = euclidean_distance(coeffs_1[0], coeffs_2[0])
    # on calcule le long de la première colonne
    for i in range(1, len(distance_matrix)):
        distance_matrix[i,0] = distance_matrix[i-1,0] + omega_v * euclidean_distance(coeffs_1[i], coeffs_2[0])
    # on calcule le long de la première ligne
    for j in range(1, len(distance_matrix[0])):
        distance_matrix[0,j] = distance_matrix[0,j-1] + omega_h * euclidean_distance(coeffs_1[0], coeffs_2[j])
    # on calcule pour le reste du tableau
    for j in range(1, len(distance_matrix[0])):
        for i in range(1, len(distance_matrix)):
            dist_h = distance_matrix[i,j-1] + omega_h * euclidean_distance(coeffs_1[i], coeffs_2[j])
            dist_v = distance_matrix[i-1,j] + omega_v * euclidean_distance(coeffs_1[i], coeffs_2[j])
            dist_d = distance_matrix[i-1,j-1] + omega_d * euclidean_distance(coeffs_1[i], coeffs_2[j])
            distance_matrix[i,j] = min(dist_h, dist_v, dist_d)
    # on retourne la distance optimale
    return distance_matrix[-1,-1] / (len(coeffs_1) + len(coeffs_2))

def distance_entre_signaux(s1, s2, window_semi_size, order, omega_v, omega_d, omega_h):
    coeffs_1 = lpc_coeffs_list(s1, window_semi_size, order)
    coeffs_2 = lpc_coeffs_list(s2, window_semi_size, order)
    return distance_elastique(coeffs_1, coeffs_2, omega_v, omega_d, omega_h)

def chargement_donnees():
    file_names = os.listdir(files_folder)
    shuffle(file_names)
    file_names = file_names[:taille_lot]
    X = [ files_folder + name for name in file_names ]
    Y = [ int(name[0]) for name in file_names ]
    delimitation = int(0.8*len(X))
    Xapp = X[:delimitation]
    Yapp = Y[:delimitation]
    Xtest = X[delimitation:]
    Ytest = Y[delimitation:]
    return Xapp, np.array(Yapp), Xtest, np.array(Ytest)

def kppv_distances(Xtest, Xapp):
    Dist = np.zeros((len(Xtest), len(Xapp)))
    for i in range(len(Xtest)):
        Fe, s1 = wav.read(Xtest[i])
        if (len(s1.shape) > 1) : s1 = s1[:,0]
        window_semi_size = int(Fe * duree_trame / 2)
        for j in range(len(Xapp)):
            _, s2 = wav.read(Xapp[j])
            if (len(s2.shape) > 1) : s2 = s2[:,0]
            Dist[i,j] = distance_entre_signaux(s1, s2, window_semi_size, order, omega_v, omega_d, omega_h)
    return Dist

def kppv_predict(Dist, Yapp, K):
    N = Dist.shape[0]
    Ypred = np.zeros(N, dtype=int)
    for i in range(N):
        kppv = Yapp[Dist[i,:].argsort()[:K]]
        Ypred[i] = np.argmax(np.bincount(kppv))
    return Ypred

def evaluation_classifieur(Ytest, Ypred):
    return (Ytest == Ypred).sum() / Ytest.shape[0]

def accuracy(Xapp, Yapp, Xtest, Ytest, K):
    Dist = kppv_distances(Xtest, Xapp)
    Ypred = kppv_predict(Dist, Yapp, K)
    print('Accuracy = {} !'.format(evaluation_classifieur(Ytest, Ypred)))

k = 3
taille_lot = 10 # 2000 maximum (déconseillé sur pc)
Xapp, Yapp, Xtest, Ytest = chargement_donnees()
accuracy(Xapp, Yapp, Xtest, Ytest, k)
            
        



    
    
